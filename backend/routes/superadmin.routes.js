const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/db');
const { authMiddleware } = require('../middleware/auth');
const { roleGuard } = require('../middleware/roleGuard');

// All superadmin routes require auth + super_admin role
router.use(authMiddleware);
router.use(roleGuard('super_admin'));

// ─────────────────────────────────────────────
// GYMS
// ─────────────────────────────────────────────
router.get('/gyms', async (req, res) => {
  try {
    const [gyms] = await db.query('SELECT * FROM gyms ORDER BY created_at DESC');
    res.json(gyms);
  } catch (err) {
    console.error('Get gyms error:', err);
    res.status(500).json({ error: err.message });
  }
});

router.post('/gyms', async (req, res) => {
  try {
    const { name, address, status, subscription_end_date } = req.body;
    const id = uuidv4();
    await db.query(
      `INSERT INTO gyms (id, name, address, status, subscription_end_date)
       VALUES (?, ?, ?, ?, ?)`,
      [id, name, address, status || 'active', subscription_end_date || null]
    );

    const [gyms] = await db.query('SELECT * FROM gyms WHERE id = ?', [id]);
    res.status(201).json(gyms[0]);
  } catch (err) {
    console.error('Create gym error:', err);
    res.status(500).json({ error: err.message });
  }
});

router.put('/gyms/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;
    
    const fields = Object.keys(updates).map(k => `\`${k}\` = ?`).join(', ');
    const values = Object.values(updates);
    
    await db.query(`UPDATE gyms SET ${fields} WHERE id = ?`, [...values, id]);
    res.json({ message: 'Gym updated successfully' });
  } catch (err) {
    console.error('Update gym error:', err);
    res.status(500).json({ error: err.message });
  }
});

router.get('/gyms/:id/admins', async (req, res) => {
  try {
    const { id } = req.params;
    const [admins] = await db.query(
      "SELECT id, email, full_name, role, phone, avatar_url, gym_id FROM users WHERE gym_id = ? AND role = 'admin'",
      [id]
    );
    res.json(admins);
  } catch (err) {
    console.error('Get gym admins error:', err);
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// USERS MANAGEMENT
// ─────────────────────────────────────────────
router.post('/users/create', async (req, res) => {
  try {
    const { email, password, full_name, phone, role, gym_id } = req.body;
    
    // Check if email exists
    const [existing] = await db.query('SELECT id FROM users WHERE email = ?', [email]);
    if (existing.length > 0) {
      return res.status(409).json({ error: 'Email already registered' });
    }

    const userId = uuidv4();
    const passwordHash = await bcrypt.hash(password, 12);

    // Start transaction
    await db.query('START TRANSACTION');
    try {
      await db.query(
        `INSERT INTO users (id, email, password_hash, full_name, phone, role, gym_id, email_verified)
         VALUES (?, ?, ?, ?, ?, ?, ?, TRUE)`,
        [userId, email, passwordHash, full_name, phone || null, role, gym_id || null]
      );

      if (role === 'trainer' && gym_id) {
        await db.query(
          `INSERT INTO trainers (id, gym_id, specialization, experience_years, bio, rating)
           VALUES (?, ?, '', 0, '', 5.0)`,
          [userId, gym_id]
        );
      }

      await db.query('COMMIT');
    } catch (txErr) {
      await db.query('ROLLBACK');
      throw txErr;
    }

    res.status(201).json({ message: 'User account created successfully', user_id: userId });
  } catch (err) {
    console.error('Superadmin create user error:', err);
    res.status(500).json({ error: err.message });
  }
});

router.put('/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { email, password, full_name, phone, role, gym_id } = req.body;

    const updates = {};
    if (email) updates.email = email;
    if (full_name) updates.full_name = full_name;
    if (phone !== undefined) updates.phone = phone;
    if (role) updates.role = role;
    if (gym_id !== undefined) updates.gym_id = gym_id;

    if (password && password.length > 0) {
      updates.password_hash = await bcrypt.hash(password, 12);
    }

    if (Object.keys(updates).length > 0) {
      const fields = Object.keys(updates).map(k => `\`${k}\` = ?`).join(', ');
      const values = Object.values(updates);
      await db.query(`UPDATE users SET ${fields} WHERE id = ?`, [...values, id]);
    }

    res.json({ message: 'User account updated successfully' });
  } catch (err) {
    console.error('Superadmin update user error:', err);
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// SUBSCRIPTIONS & PLATFORM PLANS
// ─────────────────────────────────────────────
router.post('/subscriptions', async (req, res) => {
  try {
    const { gym_id, amount, valid_from, valid_until, notes } = req.body;

    await db.query(
      `INSERT INTO gym_subscriptions (id, gym_id, amount, valid_from, valid_until, notes, recorded_by)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [uuidv4(), gym_id, amount, valid_from, valid_until, notes || null, req.user.id]
    );

    // Update gym details
    await db.query(
      "UPDATE gyms SET subscription_end_date = ?, status = 'active' WHERE id = ?",
      [valid_until, gym_id]
    );

    res.status(201).json({ message: 'Subscription added successfully' });
  } catch (err) {
    console.error('Add subscription error:', err);
    res.status(500).json({ error: err.message });
  }
});

router.get('/subscriptions/:gymId', async (req, res) => {
  try {
    const { gymId } = req.params;
    const [subscriptions] = await db.query(
      'SELECT * FROM gym_subscriptions WHERE gym_id = ? ORDER BY payment_date DESC',
      [gymId]
    );
    res.json(subscriptions);
  } catch (err) {
    console.error('Get gym subscriptions error:', err);
    res.status(500).json({ error: err.message });
  }
});

router.get('/payments', async (req, res) => {
  try {
    const [payments] = await db.query(
      `SELECT gs.*, g.name as gym_name
       FROM gym_subscriptions gs
       JOIN gyms g ON gs.gym_id = g.id
       ORDER BY gs.payment_date DESC`
    );

    const result = payments.map(p => ({
      ...p,
      gyms: { name: p.gym_name }
    }));
    
    res.json(result);
  } catch (err) {
    console.error('Get platform payments error:', err);
    res.status(500).json({ error: err.message });
  }
});

router.get('/plans', async (req, res) => {
  try {
    const [plans] = await db.query('SELECT * FROM platform_plans ORDER BY created_at DESC');
    res.json(plans);
  } catch (err) {
    console.error('Get platform plans error:', err);
    res.status(500).json({ error: err.message });
  }
});

router.post('/plans', async (req, res) => {
  try {
    const { name, description, price, duration_months } = req.body;
    await db.query(
      `INSERT INTO platform_plans (id, name, description, price, duration_months)
       VALUES (?, ?, ?, ?, ?)`,
      [uuidv4(), name, description, price, duration_months]
    );
    res.status(201).json({ message: 'Platform plan created successfully' });
  } catch (err) {
    console.error('Create platform plan error:', err);
    res.status(500).json({ error: err.message });
  }
});

router.put('/plans/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;

    const fields = Object.keys(updates).map(k => `\`${k}\` = ?`).join(', ');
    const values = Object.values(updates);

    await db.query(`UPDATE platform_plans SET ${fields} WHERE id = ?`, [...values, id]);
    res.json({ message: 'Platform plan updated successfully' });
  } catch (err) {
    console.error('Update platform plan error:', err);
    res.status(500).json({ error: err.message });
  }
});

router.delete('/plans/:id', async (req, res) => {
  try {
    const { id } = req.params;
    await db.query('DELETE FROM platform_plans WHERE id = ?', [id]);
    res.json({ message: 'Platform plan deleted successfully' });
  } catch (err) {
    console.error('Delete platform plan error:', err);
    res.status(500).json({ error: err.message });
  }
});

router.post('/plans/:id/subscribe', async (req, res) => {
  try {
    const planId = req.params.id;
    const { gym_id } = req.body;

    const [plans] = await db.query('SELECT * FROM platform_plans WHERE id = ?', [planId]);
    if (plans.length === 0) {
      return res.status(404).json({ error: 'Plan not found' });
    }
    const plan = plans[0];
    
    const now = new Date();
    const validUntil = new Date(now);
    validUntil.setDate(validUntil.getDate() + (plan.duration_months * 30));

    await db.query(
      `INSERT INTO gym_subscriptions (id, gym_id, amount, valid_from, valid_until, notes, recorded_by)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [uuidv4(), gym_id, plan.price, now.toISOString(), validUntil.toISOString(), `Subscribed to plan: ${plan.name}`, req.user.id]
    );

    await db.query(
      "UPDATE gyms SET subscription_end_date = ?, status = 'active' WHERE id = ?",
      [validUntil.toISOString(), gym_id]
    );

    res.json({ message: 'Gym subscribed to plan successfully' });
  } catch (err) {
    console.error('Subscribe gym to plan error:', err);
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// PLATFORM SETTINGS (RAZORPAY)
// ─────────────────────────────────────────────
router.get('/razorpay', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT \`key\`, value FROM app_settings 
       WHERE \`key\` IN ('superadmin_razorpay_key', 'superadmin_razorpay_secret_encrypted')
       AND gym_id IS NULL`
    );

    const result = {};
    for (const r of rows) {
      result[r.key] = r.value;
    }
    res.json(result);
  } catch (err) {
    console.error('Get platform razorpay config error:', err);
    res.status(500).json({ error: err.message });
  }
});

router.put('/razorpay', async (req, res) => {
  try {
    const { key_id, secret_encrypted } = req.body;

    const settings = [
      { key: 'superadmin_razorpay_key', value: key_id },
      { key: 'superadmin_razorpay_secret_encrypted', value: secret_encrypted }
    ];

    for (const s of settings) {
      await db.query(
        `INSERT INTO app_settings (id, gym_id, \`key\`, value)
         VALUES (?, NULL, ?, ?)
         ON DUPLICATE KEY UPDATE value = ?, updated_at = NOW()`,
        [uuidv4(), s.key, JSON.stringify(s.value), JSON.stringify(s.value)]
      );
    }

    res.json({ message: 'Platform Razorpay credentials updated' });
  } catch (err) {
    console.error('Update platform razorpay config error:', err);
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// PLATFORM LOGO
// ─────────────────────────────────────────────
router.get('/logo', async (req, res) => {
  try {
    const [rows] = await db.query(
      "SELECT value FROM app_settings WHERE `key` = 'platform_logo_url' AND gym_id IS NULL ORDER BY updated_at DESC LIMIT 1"
    );
    if (rows.length > 0) {
      return res.json({ logo_url: typeof rows[0].value === 'string' ? JSON.parse(rows[0].value) : rows[0].value });
    }
    res.json({ logo_url: null });
  } catch (err) {
    console.error('Get platform logo error:', err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
