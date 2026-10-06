const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/db');
const { authMiddleware } = require('../middleware/auth');

// All member routes require auth
router.use(authMiddleware);

function getGymId(req) {
  const gymId = req.user.gymId;
  if (!gymId) throw new Error('Gym ID is not associated with this account.');
  return gymId;
}

// ─────────────────────────────────────────────
// PROFILE
// ─────────────────────────────────────────────
router.get('/profile', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [users] = await db.query(
      'SELECT id, email, full_name, role, phone, avatar_url, gym_id, created_at FROM users WHERE id = ? AND gym_id = ?',
      [req.user.id, gymId]
    );
    res.json(users[0] || null);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/profile', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const updates = req.body;
    delete updates.id; delete updates.password_hash; delete updates.role;
    const fields = Object.keys(updates).map(k => `\`${k}\` = ?`).join(', ');
    const values = Object.values(updates);
    await db.query(`UPDATE users SET ${fields} WHERE id = ? AND gym_id = ?`, [...values, req.user.id, gymId]);
    res.json({ message: 'Profile updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/profile/password', async (req, res) => {
  try {
    const { current_password, new_password } = req.body;
    if (!current_password || !new_password) {
      return res.status(400).json({ error: 'Current password and new password are required' });
    }

    // Fetch user password_hash
    const [users] = await db.query('SELECT password_hash FROM users WHERE id = ?', [req.user.id]);
    if (users.length === 0) return res.status(404).json({ error: 'User not found' });

    const user = users[0];
    const isValid = await bcrypt.compare(current_password, user.password_hash);
    if (!isValid) {
      return res.status(400).json({ error: 'Incorrect current password' });
    }

    const hashed = await bcrypt.hash(new_password, 12);
    await db.query('UPDATE users SET password_hash = ? WHERE id = ?', [hashed, req.user.id]);

    res.json({ message: 'Password updated successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/trainer', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [assignments] = await db.query(
      'SELECT trainer_id FROM trainer_assignment WHERE member_id = ? AND gym_id = ?',
      [req.user.id, gymId]
    );
    if (assignments.length === 0) return res.json(null);

    const trainerId = assignments[0].trainer_id;
    const [users] = await db.query(
      'SELECT id, full_name, email, phone, avatar_url FROM users WHERE id = ?',
      [trainerId]
    );
    res.json(users[0] || null);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// HEALTH
// ─────────────────────────────────────────────
router.get('/health', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [rows] = await db.query('SELECT * FROM user_health WHERE user_id = ? AND gym_id = ?', [req.user.id, gymId]);
    res.json(rows[0] || null);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/health', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { height_cm, weight_kg, age, gender, blood_group, medical_conditions, allergies, goal, experience_level, onboarding_completed } = req.body;

    // Check if exists
    const [existing] = await db.query('SELECT id FROM user_health WHERE user_id = ?', [req.user.id]);

    const isCompleted = onboarding_completed === true || onboarding_completed === 1;

    if (existing.length > 0) {
      await db.query(
        `UPDATE user_health SET height_cm = ?, weight_kg = ?, age = ?, gender = ?, blood_group = ?,
         medical_conditions = ?, allergies = ?, goal = ?, experience_level = ?, onboarding_completed = ?, gym_id = ?
         WHERE user_id = ?`,
        [height_cm, weight_kg, age, gender, blood_group, medical_conditions, allergies, goal, experience_level, isCompleted, gymId, req.user.id]
      );
    } else {
      await db.query(
        `INSERT INTO user_health (id, user_id, gym_id, height_cm, weight_kg, age, gender, blood_group, medical_conditions, allergies, goal, experience_level, onboarding_completed)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [uuidv4(), req.user.id, gymId, height_cm, weight_kg, age, gender, blood_group, medical_conditions, allergies, goal, experience_level, isCompleted]
      );
    }

    res.json({ message: 'Health data saved' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// BMI
// ─────────────────────────────────────────────
router.get('/bmi', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [records] = await db.query(
      'SELECT * FROM bmi_records WHERE user_id = ? AND gym_id = ? ORDER BY recorded_at DESC LIMIT 20',
      [req.user.id, gymId]
    );
    res.json(records);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/bmi', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { bmi_value } = req.body;
    await db.query(
      'INSERT INTO bmi_records (id, user_id, gym_id, bmi_value) VALUES (?, ?, ?, ?)',
      [uuidv4(), req.user.id, gymId, bmi_value]
    );
    res.status(201).json({ message: 'BMI recorded' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// MEMBERSHIP
// ─────────────────────────────────────────────
router.get('/membership/active', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [rows] = await db.query(
      `SELECT um.*, mp.name as plan_name, mp.duration_months, mp.price, mp.features
       FROM user_membership um
       LEFT JOIN membership_plans mp ON um.plan_id = mp.id
       WHERE um.user_id = ? AND um.status = 'active' AND um.gym_id = ?
       ORDER BY um.end_date DESC LIMIT 1`,
      [req.user.id, gymId]
    );

    if (rows.length === 0) return res.json(null);

    const r = rows[0];
    res.json({
      ...r,
      membership_plans: r.plan_name ? {
        id: r.plan_id, name: r.plan_name, duration_months: r.duration_months,
        price: r.price, features: typeof r.features === 'string' ? JSON.parse(r.features) : r.features,
      } : null,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/membership/history', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [rows] = await db.query(
      `SELECT um.*, mp.name as plan_name, mp.duration_months, mp.price, mp.features
       FROM user_membership um
       LEFT JOIN membership_plans mp ON um.plan_id = mp.id
       WHERE um.user_id = ? AND um.gym_id = ?
       ORDER BY um.created_at DESC`,
      [req.user.id, gymId]
    );

    const result = rows.map(r => ({
      ...r,
      membership_plans: r.plan_name ? {
        id: r.plan_id, name: r.plan_name, duration_months: r.duration_months,
        price: r.price, features: typeof r.features === 'string' ? JSON.parse(r.features) : r.features,
      } : null,
    }));

    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/membership/plans', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [plans] = await db.query(
      'SELECT * FROM membership_plans WHERE gym_id = ? AND is_active = TRUE ORDER BY price ASC',
      [gymId]
    );
    const result = plans.map(p => ({
      ...p,
      features: typeof p.features === 'string' ? JSON.parse(p.features) : p.features,
    }));
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// PAYMENTS HISTORY
// ─────────────────────────────────────────────
router.get('/payments/history', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [rows] = await db.query(
      `SELECT p.*, mp.name as plan_name, mp.duration_months, mp.price
       FROM payments p
       LEFT JOIN membership_plans mp ON p.membership_plan_id = mp.id
       WHERE p.user_id = ? AND p.gym_id = ?
       ORDER BY p.created_at DESC`,
      [req.user.id, gymId]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/membership/purchase', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { plan_id, amount, payment_method } = req.body;

    // Generate receipt number
    const todayStr = new Date().toISOString().split('T')[0].replace(/-/g, '');
    const [[{ count }]] = await db.query(
      "SELECT COUNT(*) as count FROM payments WHERE DATE(created_at) = CURRENT_DATE() AND status = 'completed'"
    );
    const seq = (count + 1).toString().padStart(3, '0');
    const receiptNumber = `TF-${todayStr}-${seq}`;

    // Create payment record
    const paymentId = uuidv4();
    await db.query(
      `INSERT INTO payments (id, user_id, membership_plan_id, gym_id, amount, method, status, receipt_number)
       VALUES (?, ?, ?, ?, ?, ?, 'completed', ?)`,
      [paymentId, req.user.id, plan_id, gymId, amount, payment_method, receiptNumber]
    );

    // Get plan duration
    const [[plan]] = await db.query('SELECT duration_months FROM membership_plans WHERE id = ?', [plan_id]);
    const durationMonths = plan ? plan.duration_months : 1;

    // Create membership
    const startDate = new Date();
    const endDate = new Date(startDate);
    endDate.setMonth(endDate.getMonth() + durationMonths);

    await db.query(
      `INSERT INTO user_membership (id, user_id, plan_id, gym_id, start_date, end_date, status)
       VALUES (?, ?, ?, ?, ?, ?, 'active')`,
      [uuidv4(), req.user.id, plan_id, gymId, startDate.toISOString().split('T')[0], endDate.toISOString().split('T')[0]]
    );

    res.status(201).json({ message: 'Membership purchased', receipt_number: receiptNumber });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// WORKOUTS
// ─────────────────────────────────────────────
router.get('/workouts', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [assignments] = await db.query(
      `SELECT aw.*, wp.name as plan_name, wp.goal, wp.difficulty, wp.trainer_id
       FROM assigned_workouts aw
       JOIN workout_plans wp ON aw.plan_id = wp.id
       WHERE aw.user_id = ? AND aw.gym_id = ?
       ORDER BY aw.start_date DESC`,
      [req.user.id, gymId]
    );

    // Get items for each plan
    const result = [];
    for (const a of assignments) {
      const [items] = await db.query(
        'SELECT * FROM workout_plan_items WHERE plan_id = ? ORDER BY day_number, id',
        [a.plan_id]
      );
      result.push({
        ...a,
        workout_plans: {
          id: a.plan_id, name: a.plan_name, goal: a.goal, difficulty: a.difficulty,
          workout_plan_items: items,
        },
      });
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/workouts/tracking', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const today = new Date();
    const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    const endOfDay = new Date(startOfDay);
    endOfDay.setDate(endOfDay.getDate() + 1);

    const [records] = await db.query(
      'SELECT * FROM workout_tracking WHERE user_id = ? AND gym_id = ? AND completed_at >= ? AND completed_at < ?',
      [req.user.id, gymId, startOfDay.toISOString(), endOfDay.toISOString()]
    );
    res.json(records);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/workouts/tracking', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { plan_item_id, weight_used } = req.body;

    await db.query(
      `INSERT INTO workout_tracking (id, user_id, plan_item_id, gym_id, is_completed, weight_lifted)
       VALUES (?, ?, ?, ?, TRUE, ?)`,
      [uuidv4(), req.user.id, plan_item_id, gymId, weight_used || null]
    );
    res.status(201).json({ message: 'Workout logged' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/workouts/tracking', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { plan_item_id } = req.body;
    const today = new Date();
    const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    const endOfDay = new Date(startOfDay);
    endOfDay.setDate(endOfDay.getDate() + 1);

    await db.query(
      'DELETE FROM workout_tracking WHERE user_id = ? AND plan_item_id = ? AND gym_id = ? AND completed_at >= ? AND completed_at < ?',
      [req.user.id, plan_item_id, gymId, startOfDay.toISOString(), endOfDay.toISOString()]
    );
    res.json({ message: 'Workout unlogged' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/workouts/muscle-distribution', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const today = new Date();
    const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    const endOfDay = new Date(startOfDay);
    endOfDay.setDate(endOfDay.getDate() + 1);

    const [data] = await db.query(
      `SELECT wt.*, wpi.exercise_name
       FROM workout_tracking wt
       LEFT JOIN workout_plan_items wpi ON wt.plan_item_id = wpi.id
       WHERE wt.user_id = ? AND wt.gym_id = ? AND wt.completed_at >= ? AND wt.completed_at < ?`,
      [req.user.id, gymId, startOfDay.toISOString(), endOfDay.toISOString()]
    );

    if (data.length === 0) return res.json({});

    // Get exercise library for muscle group mapping
    const [library] = await db.query(
      'SELECT name, muscle_group FROM exercise_library WHERE gym_id = ?',
      [gymId]
    );
    const nameToMuscle = {};
    for (const e of library) {
      nameToMuscle[e.name.toLowerCase()] = e.muscle_group;
    }

    const counts = {};
    let total = 0;
    for (const row of data) {
      if (!row.exercise_name) continue;
      const muscle = nameToMuscle[row.exercise_name.toLowerCase()];
      if (muscle) {
        counts[muscle] = (counts[muscle] || 0) + 1;
        total++;
      }
    }

    if (total === 0) return res.json({});

    const distribution = {};
    for (const [muscle, count] of Object.entries(counts)) {
      distribution[muscle] = count / total;
    }

    res.json(distribution);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// DIETS
// ─────────────────────────────────────────────
router.get('/diets', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [assignments] = await db.query(
      `SELECT ad.*, dp.name as plan_name, dp.calories_target, dp.trainer_id
       FROM assigned_diets ad
       JOIN diet_plans dp ON ad.plan_id = dp.id
       WHERE ad.user_id = ? AND ad.gym_id = ?
       ORDER BY ad.start_date DESC`,
      [req.user.id, gymId]
    );

    const result = [];
    for (const a of assignments) {
      const [items] = await db.query(
        'SELECT * FROM diet_plan_items WHERE plan_id = ? ORDER BY day_number, id',
        [a.plan_id]
      );
      result.push({
        ...a,
        diet_plans: {
          id: a.plan_id, name: a.plan_name, calories_target: a.calories_target,
          diet_plan_items: items.map(i => ({
            ...i,
            macros: typeof i.macros === 'string' ? JSON.parse(i.macros) : i.macros,
          })),
        },
      });
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// ATTENDANCE
// ─────────────────────────────────────────────
router.post('/attendance/checkin', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { method } = req.body;
    const today = new Date();
    const startOfToday = new Date(today.getFullYear(), today.getMonth(), today.getDate());

    // Close orphaned sessions from previous days
    await db.query(
      `UPDATE attendance SET check_out = ? WHERE user_id = ? AND gym_id = ? AND check_out IS NULL AND check_in < ?`,
      [startOfToday, req.user.id, gymId, startOfToday]
    );

    // New check-in
    await db.query(
      `INSERT INTO attendance (id, user_id, gym_id, check_in, method)
       VALUES (?, ?, ?, ?, ?)`,
      [uuidv4(), req.user.id, gymId, new Date(), method || 'gps']
    );

    res.status(201).json({ message: 'Checked in' });
  } catch (err) {
    console.error('Check-in error:', err);
    res.status(500).json({ error: err.message });
  }
});

router.post('/attendance/checkout', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [records] = await db.query(
      'SELECT id FROM attendance WHERE user_id = ? AND gym_id = ? AND check_out IS NULL ORDER BY check_in DESC LIMIT 1',
      [req.user.id, gymId]
    );

    if (records.length > 0) {
      await db.query('UPDATE attendance SET check_out = ? WHERE id = ?', [new Date().toISOString(), records[0].id]);
    }

    res.json({ message: 'Checked out' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/attendance/today', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const today = new Date();
    const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate());

    const [rows] = await db.query(
      'SELECT * FROM attendance WHERE user_id = ? AND gym_id = ? AND check_in >= ? ORDER BY check_in DESC LIMIT 1',
      [req.user.id, gymId, startOfDay.toISOString()]
    );
    res.json(rows[0] || null);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/attendance/history', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [records] = await db.query(
      'SELECT * FROM attendance WHERE user_id = ? AND gym_id = ? ORDER BY check_in DESC LIMIT 150',
      [req.user.id, gymId]
    );
    res.json(records);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/attendance/monthly', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const [data] = await db.query(
      'SELECT check_in FROM attendance WHERE user_id = ? AND gym_id = ? AND check_in >= ?',
      [req.user.id, gymId, startOfMonth.toISOString()]
    );

    const uniqueDays = new Set();
    for (const r of data) {
      const d = new Date(r.check_in);
      uniqueDays.add(`${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`);
    }

    res.json({ count: uniqueDays.size });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/attendance/yearly', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const startOfYear = new Date(new Date().getFullYear(), 0, 1);

    const [data] = await db.query(
      'SELECT check_in FROM attendance WHERE user_id = ? AND gym_id = ? AND check_in >= ?',
      [req.user.id, gymId, startOfYear.toISOString()]
    );

    const uniqueDays = new Set();
    for (const r of data) {
      const d = new Date(r.check_in);
      uniqueDays.add(`${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`);
    }

    res.json({ count: uniqueDays.size });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/attendance/gym-location', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [rows] = await db.query('SELECT * FROM gym_locations WHERE gym_id = ? LIMIT 1', [gymId]);
    res.json(rows[0] || null);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// NOTIFICATIONS
// ─────────────────────────────────────────────
router.get('/notifications', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [rows] = await db.query(
      'SELECT * FROM notifications WHERE user_id = ? AND gym_id = ? ORDER BY created_at DESC LIMIT 50',
      [req.user.id, gymId]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/notifications/unread', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [[{ count }]] = await db.query(
      'SELECT COUNT(*) as count FROM notifications WHERE user_id = ? AND gym_id = ? AND is_read = FALSE',
      [req.user.id, gymId]
    );
    res.json({ count });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.patch('/notifications/:id/read', async (req, res) => {
  try {
    const gymId = getGymId(req);
    await db.query('UPDATE notifications SET is_read = TRUE WHERE id = ? AND gym_id = ?', [req.params.id, gymId]);
    res.json({ message: 'Marked as read' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.patch('/notifications/read-all', async (req, res) => {
  try {
    const gymId = getGymId(req);
    await db.query(
      'UPDATE notifications SET is_read = TRUE WHERE user_id = ? AND gym_id = ? AND is_read = FALSE',
      [req.user.id, gymId]
    );
    res.json({ message: 'All marked as read' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// ADVERTISEMENTS (member view)
// ─────────────────────────────────────────────
router.get('/ads', async (req, res) => {
  try {
    const gymId = getGymId(req);

    // 1. Determine user target segment
    let segment = 'INACTIVE';
    const [memberships] = await db.query(
      `SELECT um.*, mp.price, mp.name as plan_name 
       FROM user_membership um
       LEFT JOIN membership_plans mp ON um.plan_id = mp.id
       WHERE um.user_id = ? AND um.gym_id = ?
       ORDER BY um.end_date DESC LIMIT 1`,
      [req.user.id, gymId]
    );

    if (memberships.length > 0) {
      const mem = memberships[0];
      const endDate = new Date(mem.end_date);
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      if (mem.status === 'active' && endDate >= today) {
        const diffTime = endDate - today;
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        if (diffDays <= 7) {
          segment = 'EXPIRING';
        } else if ((mem.plan_name && mem.plan_name.toUpperCase().includes('PREMIUM')) || parseFloat(mem.price || 0) >= 2000) {
          segment = 'PREMIUM';
        } else {
          segment = 'ALL';
        }
      } else {
        segment = 'EXPIRED';
      }
    }

    // 2. Fetch active ads matching ALL or the user's specific segment
    const [ads] = await db.query(
      `SELECT * FROM advertisements
       WHERE is_active = TRUE 
         AND gym_id = ? 
         AND start_date <= NOW() 
         AND end_date >= NOW()
         AND (target_segment = 'ALL' OR target_segment = ?)
       ORDER BY created_at DESC`,
      [gymId, segment]
    );

    // 3. Map is_active to proper boolean for Dart JSON parsing
    const result = ads.map(a => ({
      ...a,
      is_active: a.is_active === 1 || a.is_active === true || a.is_active === '1'
    }));

    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/ads/:id/interact', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { interaction_type } = req.body;

    await db.query(
      'INSERT INTO ad_interactions (id, ad_id, user_id, gym_id, interaction_type) VALUES (?, ?, ?, ?, ?)',
      [uuidv4(), req.params.id, req.user.id, gymId, interaction_type]
    );
    res.status(201).json({ message: 'Interaction logged' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// COMPLAINTS
// ─────────────────────────────────────────────
router.get('/complaints', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [rows] = await db.query(
      'SELECT * FROM complaints WHERE user_id = ? AND gym_id = ? ORDER BY created_at DESC',
      [req.user.id, gymId]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
