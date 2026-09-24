const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/db');
const { authMiddleware } = require('../middleware/auth');
const { roleGuard } = require('../middleware/roleGuard');

// All admin routes require auth
router.use(authMiddleware);

// Helper: get gymId from authenticated user
function getGymId(req) {
  const gymId = req.user.gymId;
  if (!gymId) throw new Error('Gym ID is not associated with this account.');
  return gymId;
}

// GET /api/admin/exercises (accessible by trainers & members too)
router.get('/exercises', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [exercises] = await db.query(
      `SELECT e.*, u.full_name as uploader_name
       FROM exercise_library e
       LEFT JOIN users u ON e.uploaded_by = u.id
       WHERE e.gym_id = ?
       ORDER BY e.is_approved ASC, e.name ASC`,
      [gymId]
    );

    const result = exercises.map(e => ({
      ...e,
      uploader: e.uploaded_by ? { full_name: e.uploader_name } : null,
    }));

    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/complaints/submit', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { user_id, subject, description, trainer_id } = req.body;

    await db.query(
      `INSERT INTO complaints (id, user_id, trainer_id, gym_id, subject, description, status)
       VALUES (?, ?, ?, ?, ?, ?, 'pending')`,
      [uuidv4(), user_id, trainer_id || null, gymId, subject, description]
    );
    res.status(201).json({ message: 'Complaint submitted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/feedback', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { user_id, trainer_id, rating, comment } = req.body;

    await db.query(
      `INSERT INTO trainer_feedback (id, user_id, trainer_id, gym_id, rating, comment)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [uuidv4(), user_id, trainer_id, gymId, rating, comment || null]
    );

    // Update trainer average rating
    const [[{ avg_rating }]] = await db.query(
      'SELECT AVG(rating) as avg_rating FROM trainer_feedback WHERE trainer_id = ? AND gym_id = ?',
      [trainer_id, gymId]
    );
    await db.query('UPDATE trainers SET rating = ? WHERE id = ?', [parseFloat(avg_rating), trainer_id]);

    res.status(201).json({ message: 'Feedback submitted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// From here onwards, routes require admin/super_admin role
router.use(roleGuard('admin', 'super_admin'));

// ─────────────────────────────────────────────
// GET /api/admin/dashboard
// ─────────────────────────────────────────────
router.get('/dashboard', async (req, res) => {
  try {
    const gymId = getGymId(req);

    const [[{ total_users }]] = await db.query(
      "SELECT COUNT(*) as total_users FROM users WHERE role = 'member' AND gym_id = ?", [gymId]
    );
    const [[{ active_members }]] = await db.query(
      "SELECT COUNT(DISTINCT user_id) as active_members FROM user_membership WHERE status = 'active' AND gym_id = ?", [gymId]
    );
    const [[{ active_trainers }]] = await db.query(
      "SELECT COUNT(DISTINCT trainer_id) as active_trainers FROM trainer_assignment WHERE gym_id = ?", [gymId]
    );
    const [[{ total_revenue }]] = await db.query(
      "SELECT COALESCE(SUM(amount), 0) as total_revenue FROM payments WHERE status = 'completed' AND gym_id = ?", [gymId]
    );

    res.json({ total_users, active_members, active_trainers, total_revenue: parseFloat(total_revenue) });
  } catch (err) {
    console.error('Dashboard error:', err);
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// GET /api/admin/users
// ─────────────────────────────────────────────
router.get('/users', async (req, res) => {
  try {
    const gymId = getGymId(req);

    // Fetch members with their active membership + plan info
    const [users] = await db.query(
      `SELECT u.*, 
              um.id as membership_id, um.plan_id, um.start_date as mem_start, um.end_date as mem_end, um.status as mem_status,
              mp.name as plan_name, mp.duration_months, mp.price as plan_price
       FROM users u
       LEFT JOIN user_membership um ON u.id = um.user_id AND um.status = 'active' AND um.gym_id = ?
       LEFT JOIN membership_plans mp ON um.plan_id = mp.id
       WHERE u.role = 'member' AND u.gym_id = ?
       ORDER BY u.created_at DESC`,
      [gymId, gymId]
    );

    // Fetch trainer assignments
    const [assignments] = await db.query(
      `SELECT ta.member_id, u.full_name as trainer_name
       FROM trainer_assignment ta
       JOIN users u ON ta.trainer_id = u.id
       WHERE ta.gym_id = ?`,
      [gymId]
    );

    const trainerMap = {};
    for (const a of assignments) {
      trainerMap[a.member_id] = a.trainer_name;
    }

    // Format response
    const result = users.map(u => {
      const { password_hash, reset_token, reset_token_expires, refresh_token, ...safe } = u;
      safe.user_membership = u.membership_id ? [{
        id: u.membership_id,
        plan_id: u.plan_id,
        start_date: u.mem_start,
        end_date: u.mem_end,
        status: u.mem_status,
        membership_plans: u.plan_name ? {
          id: u.plan_id,
          name: u.plan_name,
          duration_months: u.duration_months,
          price: u.plan_price,
        } : null,
      }] : [];
      safe.assigned_trainer_name = trainerMap[u.id] || '';
      // Remove merged fields
      delete safe.membership_id; delete safe.plan_id; delete safe.mem_start;
      delete safe.mem_end; delete safe.mem_status; delete safe.plan_name;
      delete safe.duration_months; delete safe.plan_price;
      return safe;
    });

    res.json(result);
  } catch (err) {
    console.error('Get users error:', err);
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// PUT /api/admin/users/full-profile
// ─────────────────────────────────────────────
router.put('/users/full-profile', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { user_id, full_name, phone, email, new_password, selected_plan } = req.body;

    // 1. Update users table
    await db.query(
      'UPDATE users SET full_name = ?, phone = ?, email = ? WHERE id = ?',
      [full_name, phone, email, user_id]
    );

    // 2. Update password if provided
    if (new_password && new_password.length > 0) {
      const hash = await bcrypt.hash(new_password, 12);
      await db.query('UPDATE users SET password_hash = ? WHERE id = ?', [hash, user_id]);
    }

    // 3. Update membership if selected
    if (selected_plan) {
      const durationMonths = parseInt(selected_plan.duration_months, 10) || 1;
      const startDate = new Date();
      const endDate = new Date(startDate);
      endDate.setMonth(endDate.getMonth() + durationMonths);

      // Deactivate old
      await db.query(
        "UPDATE user_membership SET status = 'cancelled' WHERE user_id = ? AND gym_id = ?",
        [user_id, gymId]
      );

      // Insert new
      await db.query(
        `INSERT INTO user_membership (id, user_id, plan_id, start_date, end_date, status, gym_id)
         VALUES (?, ?, ?, ?, ?, 'active', ?)`,
        [uuidv4(), user_id, selected_plan.id, startDate.toISOString().split('T')[0], endDate.toISOString().split('T')[0], gymId]
      );

      // Record offline/cash payment
      const todayStr = new Date().toISOString().split('T')[0].replace(/-/g, '');
      const [[{ count }]] = await db.query(
        "SELECT COUNT(*) as count FROM payments WHERE DATE(created_at) = CURRENT_DATE() AND status = 'completed'"
      );
      const seq = (count + 1).toString().padStart(3, '0');
      const receiptNumber = `TF-${todayStr}-${seq}`;

      await db.query(
        `INSERT INTO payments (id, user_id, membership_plan_id, gym_id, amount, method, status, receipt_number)
         VALUES (?, ?, ?, ?, ?, 'cash', 'completed', ?)`,
        [uuidv4(), user_id, selected_plan.id, gymId, parseFloat(selected_plan.price), receiptNumber]
      );
    }

    res.json({ message: 'Profile updated' });
  } catch (err) {
    console.error('Update full profile error:', err);
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// PUT /api/admin/users/:id
// ─────────────────────────────────────────────
router.put('/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;
    // Remove sensitive fields from updates
    delete updates.password_hash; delete updates.id;

    const fields = Object.keys(updates).map(k => `${k} = ?`).join(', ');
    const values = Object.values(updates);

    await db.query(`UPDATE users SET ${fields} WHERE id = ?`, [...values, id]);
    res.json({ message: 'User updated' });
  } catch (err) {
    console.error('Update user error:', err);
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// PATCH /api/admin/users/:id/role
// ─────────────────────────────────────────────
router.patch('/users/:id/role', async (req, res) => {
  try {
    const { id } = req.params;
    const { role } = req.body;
    await db.query('UPDATE users SET role = ? WHERE id = ?', [role, id]);
    res.json({ message: 'Role updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// DELETE /api/admin/users/:id
// ─────────────────────────────────────────────
router.delete('/users/:id', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { id } = req.params;
    await db.query('DELETE FROM users WHERE id = ? AND gym_id = ?', [id, gymId]);
    res.json({ message: 'User account deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// ─────────────────────────────────────────────
// POST /api/admin/users/create
// ─────────────────────────────────────────────
router.post('/users/create', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { email, password, full_name, phone, selected_plan, role } = req.body;

    // Check if email exists
    const [existing] = await db.query('SELECT id FROM users WHERE email = ?', [email]);
    if (existing.length > 0) {
      return res.status(409).json({ error: 'Email already registered' });
    }

    const userId = uuidv4();
    const passwordHash = await bcrypt.hash(password, 12);
    const userRole = role || 'member';

    // Start transaction
    await db.query('START TRANSACTION');
    try {
      await db.query(
        `INSERT INTO users (id, email, password_hash, full_name, phone, role, gym_id, email_verified)
         VALUES (?, ?, ?, ?, ?, ?, ?, TRUE)`,
        [userId, email, passwordHash, full_name, phone, userRole, gymId]
      );

      // Assign membership if selected
      if (selected_plan && userRole === 'member') {
        const durationMonths = selected_plan.duration_months || 1;
        const startDate = new Date();
        const endDate = new Date(startDate);
        endDate.setMonth(endDate.getMonth() + durationMonths);

        await db.query(
          `INSERT INTO user_membership (id, user_id, plan_id, start_date, end_date, status, gym_id)
           VALUES (?, ?, ?, ?, ?, 'active', ?)`,
          [uuidv4(), userId, selected_plan.id, startDate.toISOString().split('T')[0], endDate.toISOString().split('T')[0], gymId]
        );

        // Record offline/cash payment
        const todayStr = new Date().toISOString().split('T')[0].replace(/-/g, '');
        const [[{ count }]] = await db.query(
          "SELECT COUNT(*) as count FROM payments WHERE DATE(created_at) = CURRENT_DATE() AND status = 'completed'"
        );
        const seq = (count + 1).toString().padStart(3, '0');
        const receiptNumber = `TF-${todayStr}-${seq}`;

        await db.query(
          `INSERT INTO payments (id, user_id, membership_plan_id, gym_id, amount, method, status, receipt_number)
           VALUES (?, ?, ?, ?, ?, 'cash', 'completed', ?)`,
          [uuidv4(), userId, selected_plan.id, gymId, parseFloat(selected_plan.price), receiptNumber]
        );
      }

      // Create trainer profile if role is trainer
      if (userRole === 'trainer') {
        await db.query(
          `INSERT INTO trainers (id, gym_id, specialization, experience_years, bio, rating)
           VALUES (?, ?, '', 0, '', 5.0)`,
          [userId, gymId]
        );
      }

      await db.query('COMMIT');
    } catch (txErr) {
      await db.query('ROLLBACK');
      throw txErr;
    }

    res.status(201).json({ message: 'User created successfully', user_id: userId });
  } catch (err) {
    console.error('Create user error:', err);
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// GET /api/admin/trainers
// ─────────────────────────────────────────────
router.get('/trainers', async (req, res) => {
  try {
    const gymId = getGymId(req);

    const [trainers] = await db.query(
      `SELECT t.*, u.full_name, u.email, u.phone, u.avatar_url
       FROM trainers t
       JOIN users u ON t.id = u.id
       WHERE t.gym_id = ?
       ORDER BY t.experience_years DESC`,
      [gymId]
    );

    // Get assignments
    const [assignments] = await db.query(
      `SELECT ta.trainer_id, ta.member_id, u.full_name as member_name
       FROM trainer_assignment ta
       JOIN users u ON ta.member_id = u.id
       WHERE ta.gym_id = ?`,
      [gymId]
    );

    const assignmentMap = {};
    for (const a of assignments) {
      if (!assignmentMap[a.trainer_id]) assignmentMap[a.trainer_id] = [];
      assignmentMap[a.trainer_id].push({ member_id: a.member_id, member_name: a.member_name });
    }

    const result = trainers.map(t => ({
      ...t,
      users: { id: t.id, full_name: t.full_name, email: t.email, phone: t.phone, avatar_url: t.avatar_url },
      assigned_members: assignmentMap[t.id] || [],
    }));

    res.json(result);
  } catch (err) {
    console.error('Get trainers error:', err);
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// POST /api/admin/trainers/create
// ─────────────────────────────────────────────
router.post('/trainers/create', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { email, password, full_name, phone, specialization, experience_years, bio } = req.body;

    const [existing] = await db.query('SELECT id FROM users WHERE email = ?', [email]);
    if (existing.length > 0) {
      return res.status(409).json({ error: 'Email already registered' });
    }

    const userId = uuidv4();
    const passwordHash = await bcrypt.hash(password, 12);

    // Create user with trainer role
    await db.query(
      `INSERT INTO users (id, email, password_hash, full_name, phone, role, gym_id, email_verified)
       VALUES (?, ?, ?, ?, ?, 'trainer', ?, TRUE)`,
      [userId, email, passwordHash, full_name, phone, gymId]
    );

    // Create trainer profile
    await db.query(
      `INSERT INTO trainers (id, gym_id, specialization, experience_years, bio, rating)
       VALUES (?, ?, ?, ?, ?, 5.0)`,
      [userId, gymId, specialization || '', experience_years || 0, bio || '']
    );

    res.status(201).json({ message: 'Trainer created', user_id: userId });
  } catch (err) {
    console.error('Create trainer error:', err);
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// POST /api/admin/trainers/promote
// ─────────────────────────────────────────────
router.post('/trainers/promote', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { user_id, specialization, experience_years, bio } = req.body;

    await db.query("UPDATE users SET role = 'trainer' WHERE id = ?", [user_id]);
    await db.query(
      `INSERT INTO trainers (id, gym_id, specialization, experience_years, bio, rating)
       VALUES (?, ?, ?, ?, ?, 5.0)`,
      [user_id, gymId, specialization || '', experience_years || 0, bio || '']
    );

    res.json({ message: 'Member promoted to trainer' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// PUT /api/admin/trainers/:id
// ─────────────────────────────────────────────
router.put('/trainers/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { full_name, phone, email, specialization, experience_years, bio, new_password } = req.body;

    await db.query('UPDATE users SET full_name = ?, phone = ? WHERE id = ?', [full_name, phone, id]);

    await db.query(
      'UPDATE trainers SET specialization = ?, experience_years = ?, bio = ? WHERE id = ?',
      [specialization, experience_years, bio, id]
    );

    if (email) {
      await db.query('UPDATE users SET email = ? WHERE id = ?', [email, id]);
    }

    if (new_password && new_password.length > 0) {
      const hash = await bcrypt.hash(new_password, 12);
      await db.query('UPDATE users SET password_hash = ? WHERE id = ?', [hash, id]);
    }

    res.json({ message: 'Trainer updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// POST /api/admin/trainers/assign
// ─────────────────────────────────────────────
router.post('/trainers/assign', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { trainer_id, member_id } = req.body;

    // Upsert — one trainer per member (delete old, insert new)
    await db.query('DELETE FROM trainer_assignment WHERE member_id = ?', [member_id]);
    await db.query(
      `INSERT INTO trainer_assignment (id, trainer_id, member_id, gym_id)
       VALUES (?, ?, ?, ?)`,
      [uuidv4(), trainer_id, member_id, gymId]
    );

    res.json({ message: 'Trainer assigned' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// DELETE /api/admin/trainers/unassign/:memberId
// ─────────────────────────────────────────────
router.delete('/trainers/unassign/:memberId', async (req, res) => {
  try {
    await db.query('DELETE FROM trainer_assignment WHERE member_id = ?', [req.params.memberId]);
    res.json({ message: 'Assignment removed' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// GET /api/admin/members/unassigned
// ─────────────────────────────────────────────
router.get('/members/unassigned', async (req, res) => {
  try {
    const gymId = getGymId(req);

    const [members] = await db.query(
      `SELECT u.id, u.full_name, u.email FROM users u
       WHERE u.role = 'member' AND u.gym_id = ?
       AND u.id NOT IN (SELECT member_id FROM trainer_assignment WHERE gym_id = ?)`,
      [gymId, gymId]
    );

    res.json(members);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// MEMBERSHIP PLANS CRUD
// ─────────────────────────────────────────────
router.get('/plans', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [plans] = await db.query(
      'SELECT * FROM membership_plans WHERE is_active = TRUE AND gym_id = ? ORDER BY price ASC',
      [gymId]
    );
    // Parse JSON features
    const result = plans.map(p => ({ ...p, features: typeof p.features === 'string' ? JSON.parse(p.features) : p.features }));
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/plans', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { name, duration_months, price, features } = req.body;

    await db.query(
      `INSERT INTO membership_plans (id, gym_id, name, duration_months, price, features, is_active)
       VALUES (?, ?, ?, ?, ?, ?, TRUE)`,
      [uuidv4(), gymId, name, duration_months, price, JSON.stringify(features || [])]
    );

    res.status(201).json({ message: 'Plan created' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/plans/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;
    if (updates.features) updates.features = JSON.stringify(updates.features);

    const fields = Object.keys(updates).map(k => `\`${k}\` = ?`).join(', ');
    const values = Object.values(updates);
    await db.query(`UPDATE membership_plans SET ${fields} WHERE id = ?`, [...values, id]);
    res.json({ message: 'Plan updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.patch('/plans/:id/toggle', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { is_active } = req.body;
    await db.query(
      'UPDATE membership_plans SET is_active = ? WHERE id = ? AND gym_id = ?',
      [is_active, req.params.id, gymId]
    );
    res.json({ message: 'Plan toggled' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// PAYMENTS
// ─────────────────────────────────────────────
router.get('/payments', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [payments] = await db.query(
      `SELECT p.*, u.full_name, u.email, mp.name as plan_name
       FROM payments p
       JOIN users u ON p.user_id = u.id
       LEFT JOIN membership_plans mp ON p.membership_plan_id = mp.id
       WHERE p.gym_id = ?
       ORDER BY p.created_at DESC`,
      [gymId]
    );

    const result = payments.map(p => ({
      ...p,
      users: { full_name: p.full_name, email: p.email },
      plan_name: p.plan_name || 'N/A',
    }));

    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.patch('/payments/:id/status', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { status } = req.body;
    await db.query(
      'UPDATE payments SET status = ? WHERE id = ? AND gym_id = ?',
      [status, req.params.id, gymId]
    );
    res.json({ message: 'Payment status updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/revenue', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const firstOfMonth = new Date();
    firstOfMonth.setDate(1);
    firstOfMonth.setHours(0, 0, 0, 0);

    const [[{ total_revenue }]] = await db.query(
      "SELECT COALESCE(SUM(amount), 0) as total_revenue FROM payments WHERE status = 'completed' AND gym_id = ?",
      [gymId]
    );
    const [[{ monthly_revenue }]] = await db.query(
      "SELECT COALESCE(SUM(amount), 0) as monthly_revenue FROM payments WHERE status = 'completed' AND gym_id = ? AND created_at >= ?",
      [gymId, firstOfMonth.toISOString()]
    );
    const [[{ total_transactions }]] = await db.query(
      "SELECT COUNT(*) as total_transactions FROM payments WHERE status = 'completed' AND gym_id = ?",
      [gymId]
    );

    res.json({ total_revenue: parseFloat(total_revenue), monthly_revenue: parseFloat(monthly_revenue), total_transactions });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// COMPLAINTS & FEEDBACK
// ─────────────────────────────────────────────
router.get('/complaints', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [complaints] = await db.query(
      `SELECT c.*, u.full_name, u.email, tu.full_name as trainer_name
       FROM complaints c
       JOIN users u ON c.user_id = u.id
       LEFT JOIN users tu ON c.trainer_id = tu.id
       WHERE c.gym_id = ?
       ORDER BY c.created_at DESC`,
      [gymId]
    );

    const result = complaints.map(c => ({
      ...c,
      users: { full_name: c.full_name, email: c.email },
      trainer: c.trainer_id ? { users: { full_name: c.trainer_name } } : null,
    }));

    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.patch('/complaints/:id/status', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { status } = req.body;
    await db.query('UPDATE complaints SET status = ? WHERE id = ? AND gym_id = ?', [status, req.params.id, gymId]);
    res.json({ message: 'Complaint status updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/feedback', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [feedback] = await db.query(
      `SELECT tf.*, u.full_name as user_name, tu.full_name as trainer_name, t.*
       FROM trainer_feedback tf
       JOIN users u ON tf.user_id = u.id
       LEFT JOIN trainers t ON tf.trainer_id = t.id
       LEFT JOIN users tu ON t.id = tu.id
       WHERE tf.gym_id = ?
       ORDER BY tf.created_at DESC`,
      [gymId]
    );

    const result = feedback.map(f => ({
      ...f,
      users: { full_name: f.user_name },
      trainers: f.trainer_id ? {
        id: f.trainer_id,
        specialization: f.specialization,
        experience_years: f.experience_years,
        bio: f.bio,
        rating: f.rating,
        users: { id: f.trainer_id, full_name: f.trainer_name },
      } : null,
    }));

    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// EXERCISE / VIDEO LIBRARY
// ─────────────────────────────────────────────

router.post('/exercises', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { name, muscle_group, difficulty, description, video_url } = req.body;

    await db.query(
      `INSERT INTO exercise_library (id, gym_id, name, muscle_group, difficulty, description, video_url, is_approved)
       VALUES (?, ?, ?, ?, ?, ?, ?, TRUE)`,
      [uuidv4(), gymId, name, muscle_group, difficulty, description || null, video_url || null]
    );

    res.status(201).json({ message: 'Exercise added' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/exercises/:id', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const updates = req.body;
    const fields = Object.keys(updates).map(k => `\`${k}\` = ?`).join(', ');
    const values = Object.values(updates);
    await db.query(`UPDATE exercise_library SET ${fields} WHERE id = ? AND gym_id = ?`, [...values, req.params.id, gymId]);
    res.json({ message: 'Exercise updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.patch('/exercises/:id/approve', async (req, res) => {
  try {
    const gymId = getGymId(req);
    await db.query('UPDATE exercise_library SET is_approved = TRUE WHERE id = ? AND gym_id = ?', [req.params.id, gymId]);
    res.json({ message: 'Exercise approved' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/exercises/:id', async (req, res) => {
  try {
    const gymId = getGymId(req);
    await db.query('DELETE FROM exercise_library WHERE id = ? AND gym_id = ?', [req.params.id, gymId]);
    res.json({ message: 'Exercise deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// REMINDERS
// ─────────────────────────────────────────────
router.get('/reminders', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [logs] = await db.query(
      `SELECT r.*, u.full_name, u.email
       FROM reminder_logs r
       JOIN users u ON r.user_id = u.id
       WHERE r.gym_id = ?
       ORDER BY r.sent_at DESC LIMIT 200`,
      [gymId]
    );

    const result = logs.map(r => ({ ...r, users: { full_name: r.full_name, email: r.email } }));
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/expiring-members', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const days = parseInt(req.query.days || '7');
    const today = new Date().toISOString().split('T')[0];
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() + days);
    const cutoffStr = cutoff.toISOString().split('T')[0];

    const [members] = await db.query(
      `SELECT um.*, u.id as uid, u.full_name, u.email, u.phone
       FROM user_membership um
       JOIN users u ON um.user_id = u.id
       WHERE um.status = 'active' AND um.gym_id = ?
       AND um.end_date >= ? AND um.end_date <= ?
       ORDER BY um.end_date ASC`,
      [gymId, today, cutoffStr]
    );

    const result = members.map(m => ({
      ...m,
      users: { id: m.uid, full_name: m.full_name, email: m.email, phone: m.phone },
    }));

    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/reminders', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { user_id, type } = req.body;
    const now = new Date().toISOString();

    await db.query(
      'INSERT INTO reminder_logs (id, user_id, gym_id, type, sent_at) VALUES (?, ?, ?, ?, ?)',
      [uuidv4(), user_id, gymId, type, now]
    );

    // Insert notification
    const titles = {
      expiry_warning: '⏰ Membership Expiring Soon',
      payment_due: '💳 Payment Due',
      welcome: '🎉 Welcome to the Gym!',
    };
    const bodies = {
      expiry_warning: 'Your gym membership is expiring soon. Renew now to keep access!',
      payment_due: 'You have a pending payment. Please clear it at the earliest.',
      welcome: "Your membership is now active. Let's crush those goals!",
    };

    await db.query(
      'INSERT INTO notifications (id, user_id, gym_id, title, body, is_read) VALUES (?, ?, ?, ?, ?, FALSE)',
      [uuidv4(), user_id, gymId, titles[type] || '🔔 Reminder', bodies[type] || 'You have a new reminder.']
    );

    res.status(201).json({ message: 'Reminder sent' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/reminders/bulk', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { user_ids } = req.body;
    if (!user_ids || user_ids.length === 0) return res.json({ count: 0 });

    const uniqueIds = [...new Set(user_ids)];
    const now = new Date().toISOString();

    for (const uid of uniqueIds) {
      await db.query(
        'INSERT INTO reminder_logs (id, user_id, gym_id, type, sent_at) VALUES (?, ?, ?, ?, ?)',
        [uuidv4(), uid, gymId, 'expiry_warning', now]
      );
      await db.query(
        'INSERT INTO notifications (id, user_id, gym_id, title, body, is_read) VALUES (?, ?, ?, ?, ?, FALSE)',
        [uuidv4(), uid, gymId, '⏰ Membership Expiring Soon', 'Your gym membership is expiring soon. Renew now to keep access!']
      );
    }

    res.json({ count: uniqueIds.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/reminders/stats', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const firstOfMonth = new Date();
    firstOfMonth.setDate(1);
    firstOfMonth.setHours(0, 0, 0, 0);

    const [[{ total_this_month }]] = await db.query(
      'SELECT COUNT(*) as total_this_month FROM reminder_logs WHERE gym_id = ? AND sent_at >= ?',
      [gymId, firstOfMonth.toISOString()]
    );
    const [[{ unique_members }]] = await db.query(
      'SELECT COUNT(DISTINCT user_id) as unique_members FROM reminder_logs WHERE gym_id = ? AND sent_at >= ?',
      [gymId, firstOfMonth.toISOString()]
    );

    res.json({ total_this_month, unique_members });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/reminders', async (req, res) => {
  try {
    const gymId = getGymId(req);
    await db.query('DELETE FROM reminder_logs WHERE gym_id = ?', [gymId]);
    res.json({ message: 'Reminder logs cleared' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// ADVERTISEMENTS
// ─────────────────────────────────────────────
router.get('/advertisements', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [ads] = await db.query('SELECT * FROM advertisements WHERE gym_id = ? ORDER BY created_at DESC', [gymId]);
    const result = ads.map(a => ({
      ...a,
      is_active: a.is_active === 1 || a.is_active === true || a.is_active === '1'
    }));
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/advertisements', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { title, image_url, target_segment, redirect_type, redirect_url, start_date, end_date, is_active } = req.body;

    await db.query(
      `INSERT INTO advertisements (id, gym_id, title, image_url, target_segment, redirect_type, redirect_url, start_date, end_date, is_active)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [uuidv4(), gymId, title, image_url, target_segment, redirect_type, redirect_url || null, start_date, end_date, is_active !== false]
    );

    res.status(201).json({ message: 'Advertisement created' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/advertisements/:id', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const updates = req.body;
    const fields = Object.keys(updates).map(k => `\`${k}\` = ?`).join(', ');
    const values = Object.values(updates);
    await db.query(`UPDATE advertisements SET ${fields} WHERE id = ? AND gym_id = ?`, [...values, req.params.id, gymId]);
    res.json({ message: 'Advertisement updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/advertisements/:id', async (req, res) => {
  try {
    const gymId = getGymId(req);
    await db.query('DELETE FROM advertisements WHERE id = ? AND gym_id = ?', [req.params.id, gymId]);
    res.json({ message: 'Advertisement deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/advertisements/:id/performance', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [interactions] = await db.query(
      'SELECT interaction_type FROM ad_interactions WHERE ad_id = ? AND gym_id = ?',
      [req.params.id, gymId]
    );

    let views = 0, clicks = 0;
    for (const i of interactions) {
      if (i.interaction_type === 'VIEW') views++;
      if (i.interaction_type === 'CLICK') clicks++;
    }

    res.json({ views, clicks, ctr: views > 0 ? (clicks / views) * 100 : 0 });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// GYM LOCATION & SETTINGS
// ─────────────────────────────────────────────
router.get('/gym/location', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [locs] = await db.query('SELECT * FROM gym_locations WHERE gym_id = ? LIMIT 1', [gymId]);
    res.json(locs[0] || null);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/gym/info', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { name, address, phone, email, latitude, longitude, radius_meters } = req.body;

    await db.query('UPDATE gyms SET name = ?, address = ? WHERE id = ?', [name, address, gymId]);

    const [existing] = await db.query('SELECT id FROM gym_locations WHERE gym_id = ? LIMIT 1', [gymId]);
    if (existing.length > 0) {
      await db.query(
        `UPDATE gym_locations SET name = ?, address = ?, phone = ?, email = ?, latitude = ?, longitude = ?, radius_meters = ?
         WHERE id = ? AND gym_id = ?`,
        [name, address, phone, email, latitude, longitude, radius_meters, existing[0].id, gymId]
      );
    } else {
      await db.query(
        `INSERT INTO gym_locations (id, gym_id, name, address, phone, email, latitude, longitude, radius_meters)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [uuidv4(), gymId, name, address, phone, email, latitude, longitude, radius_meters]
      );
    }

    res.json({ message: 'Gym info updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/gym/subscription', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [gyms] = await db.query(
      'SELECT name, status, subscription_end_date, logo_url, razorpay_key, razorpay_secret_encrypted FROM gyms WHERE id = ?',
      [gymId]
    );
    res.json(gyms[0] || {});
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/gym/subscription', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { status, end_date } = req.body;
    await db.query('UPDATE gyms SET status = ?, subscription_end_date = ? WHERE id = ?', [status, end_date, gymId]);
    res.json({ message: 'Subscription updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/gym/razorpay', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { key_id, secret_encrypted } = req.body;
    await db.query(
      'UPDATE gyms SET razorpay_key = ?, razorpay_secret_encrypted = ? WHERE id = ?',
      [key_id, secret_encrypted, gymId]
    );
    res.json({ message: 'Razorpay credentials updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/settings', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [rows] = await db.query('SELECT `key`, value FROM app_settings WHERE gym_id = ?', [gymId]);
    const settings = {};
    for (const row of rows) {
      // MySQL JSON column may return raw values or stringified JSON — normalize
      let val = row.value;
      if (typeof val === 'string') {
        try { val = JSON.parse(val); } catch (_) { /* keep as string */ }
      }
      if (val === 'true' || val === '1' || val === 1) val = true;
      if (val === 'false' || val === '0' || val === 0) val = false;
      settings[row.key] = val;
    }
    res.json(settings);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/settings', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { key, value } = req.body;
    await db.query(
      `INSERT INTO app_settings (id, gym_id, \`key\`, value) VALUES (?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE value = ?, updated_at = NOW()`,
      [uuidv4(), gymId, key, JSON.stringify(value), JSON.stringify(value)]
    );
    res.json({ message: 'Setting updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/profile', async (req, res) => {
  try {
    const { full_name } = req.body;
    await db.query('UPDATE users SET full_name = ? WHERE id = ?', [full_name, req.user.id]);
    res.json({ message: 'Profile updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// ATTENDANCE (Admin view)
// ─────────────────────────────────────────────
router.get('/attendance/today', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const today = new Date();
    const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate());

    const [records] = await db.query(
      `SELECT a.*, u.full_name, u.role
       FROM attendance a
       JOIN users u ON a.user_id = u.id
       WHERE a.gym_id = ? AND a.check_in >= ?
       ORDER BY a.check_in DESC`,
      [gymId, startOfDay.toISOString()]
    );

    const result = records.map(r => ({
      ...r,
      users: { full_name: r.full_name, role: r.role },
    }));

    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/attendance/trainers', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { trainer_ids } = req.body;
    if (!trainer_ids || trainer_ids.length === 0) return res.json({});

    const today = new Date();
    const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate());

    const placeholders = trainer_ids.map(() => '?').join(',');
    const [records] = await db.query(
      `SELECT * FROM attendance
       WHERE gym_id = ? AND user_id IN (${placeholders}) AND check_in >= ?
       ORDER BY check_in DESC`,
      [gymId, ...trainer_ids, startOfDay.toISOString()]
    );

    const result = {};
    for (const r of records) {
      if (!result[r.user_id]) {
        result[r.user_id] = r;
      }
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// LEADS
// ─────────────────────────────────────────────
router.get('/leads', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [leads] = await db.query(
      'SELECT * FROM leads WHERE gym_id = ? ORDER BY created_at DESC',
      [gymId]
    );
    res.json(leads);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/leads', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { full_name, email, phone, status, source, notes } = req.body;
    const id = uuidv4();

    await db.query(
      `INSERT INTO leads (id, gym_id, full_name, email, phone, status, source, notes)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [id, gymId, full_name, email || null, phone, status || 'new', source || null, notes || null]
    );

    const [[lead]] = await db.query('SELECT * FROM leads WHERE id = ?', [id]);
    res.status(201).json(lead);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/leads/:id', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { id } = req.params;
    const updates = req.body;
    delete updates.id; delete updates.gym_id; delete updates.created_at;

    const fields = Object.keys(updates).map(k => `\`${k}\` = ?`).join(', ');
    const values = Object.values(updates);

    await db.query(
      `UPDATE leads SET ${fields} WHERE id = ? AND gym_id = ?`,
      [...values, id, gymId]
    );

    const [[lead]] = await db.query('SELECT * FROM leads WHERE id = ?', [id]);
    res.json(lead);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/leads/:id', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { id } = req.params;
    await db.query('DELETE FROM leads WHERE id = ? AND gym_id = ?', [id, gymId]);
    res.json({ message: 'Lead deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
