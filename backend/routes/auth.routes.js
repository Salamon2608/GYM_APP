const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/db');
const { authMiddleware } = require('../middleware/auth');

// Helper: generate tokens
function generateTokens(user) {
  const accessToken = jwt.sign(
    { id: user.id, email: user.email, role: user.role, gymId: user.gym_id },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
  const refreshToken = jwt.sign(
    { id: user.id, type: 'refresh' },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d' }
  );
  return { accessToken, refreshToken };
}

// Helper: sanitize user for response (remove sensitive fields)t
function sanitizeUser(user) {
  const { password_hash, reset_token, reset_token_expires, refresh_token, ...safe } = user;
  return safe;
}

// ─────────────────────────────────────────────
// POST /api/auth/signup
// ─────────────────────────────────────────────
router.post('/signup', async (req, res) => {
  try {
    const { email, password, full_name, phone, gym_id, role } = req.body;

    if (!email || !password || !full_name) {
      return res.status(400).json({ error: 'Email, password, and full_name are required' });
    }

    // Check if email exists
    const [existing] = await db.query('SELECT id FROM users WHERE email = ?', [email]);
    if (existing.length > 0) {
      return res.status(409).json({ error: 'Email already registered' });
    }

    const id = uuidv4();
    const passwordHash = await bcrypt.hash(password, 12);
    const userRole = role || 'member';

    await db.query(
      `INSERT INTO users (id, email, password_hash, full_name, phone, role, gym_id, email_verified)
       VALUES (?, ?, ?, ?, ?, ?, ?, TRUE)`,
      [id, email, passwordHash, full_name, phone || null, userRole, gym_id || null]
    );

    // Fetch the created user
    const [users] = await db.query('SELECT * FROM users WHERE id = ?', [id]);
    const user = users[0];

    const tokens = generateTokens(user);

    // Store refresh token
    await db.query('UPDATE users SET refresh_token = ? WHERE id = ?', [tokens.refreshToken, id]);

    res.status(201).json({
      user: sanitizeUser(user),
      access_token: tokens.accessToken,
      refresh_token: tokens.refreshToken,
    });
  } catch (err) {
    console.error('Signup error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ─────────────────────────────────────────────
// POST /api/auth/login
// ─────────────────────────────────────────────
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    const [users] = await db.query('SELECT * FROM users WHERE email = ?', [email]);
    if (users.length === 0) {
      return res.status(401).json({ error: 'Invalid login credentials' });
    }

    const user = users[0];
    const isValid = await bcrypt.compare(password, user.password_hash);
    if (!isValid) {
      return res.status(401).json({ error: 'Invalid login credentials' });
    }

    const tokens = generateTokens(user);

    // Store refresh token
    await db.query('UPDATE users SET refresh_token = ? WHERE id = ?', [tokens.refreshToken, user.id]);

    // Fetch gym info if user belongs to a gym
    let gym = null;
    if (user.gym_id) {
      const [gyms] = await db.query(
        'SELECT id, name, status, subscription_end_date, logo_url FROM gyms WHERE id = ?',
        [user.gym_id]
      );
      if (gyms.length > 0) gym = gyms[0];
    }

    res.json({
      user: sanitizeUser(user),
      gym,
      access_token: tokens.accessToken,
      refresh_token: tokens.refreshToken,
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ─────────────────────────────────────────────
// POST /api/auth/logout
// ─────────────────────────────────────────────
router.post('/logout', authMiddleware, async (req, res) => {
  try {
    await db.query('UPDATE users SET refresh_token = NULL WHERE id = ?', [req.user.id]);
    res.json({ message: 'Logged out successfully' });
  } catch (err) {
    console.error('Logout error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ─────────────────────────────────────────────
// GET /api/auth/me
// ─────────────────────────────────────────────
router.get('/me', authMiddleware, async (req, res) => {
  try {
    const [users] = await db.query('SELECT * FROM users WHERE id = ?', [req.user.id]);
    if (users.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const user = users[0];
    let gym = null;
    if (user.gym_id) {
      const [gyms] = await db.query(
        'SELECT id, name, status, subscription_end_date, logo_url FROM gyms WHERE id = ?',
        [user.gym_id]
      );
      if (gyms.length > 0) gym = gyms[0];
    }

    res.json({ user: sanitizeUser(user), gym });
  } catch (err) {
    console.error('Me error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ─────────────────────────────────────────────
// POST /api/auth/refresh
// ─────────────────────────────────────────────
router.post('/refresh', async (req, res) => {
  try {
    const { refresh_token } = req.body;
    if (!refresh_token) {
      return res.status(400).json({ error: 'Refresh token required' });
    }

    let decoded;
    try {
      decoded = jwt.verify(refresh_token, process.env.JWT_SECRET);
    } catch {
      return res.status(401).json({ error: 'Invalid or expired refresh token' });
    }

    const [users] = await db.query('SELECT * FROM users WHERE id = ? AND refresh_token = ?', [decoded.id, refresh_token]);
    if (users.length === 0) {
      return res.status(401).json({ error: 'Invalid refresh token' });
    }

    const user = users[0];
    const tokens = generateTokens(user);

    await db.query('UPDATE users SET refresh_token = ? WHERE id = ?', [tokens.refreshToken, user.id]);

    res.json({
      access_token: tokens.accessToken,
      refresh_token: tokens.refreshToken,
    });
  } catch (err) {
    console.error('Refresh error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ─────────────────────────────────────────────
// POST /api/auth/forgot-password
// ─────────────────────────────────────────────
router.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ error: 'Email is required' });

    const [users] = await db.query('SELECT id FROM users WHERE email = ?', [email]);
    if (users.length === 0) {
      // Don't reveal if email exists
      return res.json({ message: 'If the email exists, a reset code has been sent.' });
    }

    // Generate 6-digit OTP
    const otp = crypto.randomInt(100000, 999999).toString();
    const expires = new Date(Date.now() + 15 * 60 * 1000); // 15 min

    await db.query(
      'UPDATE users SET reset_token = ?, reset_token_expires = ? WHERE email = ?',
      [otp, expires, email]
    );

    // TODO: Send email via Nodemailer
    // For development, log the OTP
    console.log(`[DEV] Password reset OTP for ${email}: ${otp}`);

    res.json({ message: 'If the email exists, a reset code has been sent.' });
  } catch (err) {
    console.error('Forgot password error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ─────────────────────────────────────────────
// POST /api/auth/verify-otp
// ─────────────────────────────────────────────
router.post('/verify-otp', async (req, res) => {
  try {
    const { email, otp } = req.body;
    if (!email || !otp) return res.status(400).json({ error: 'Email and OTP are required' });

    const [users] = await db.query(
      'SELECT * FROM users WHERE email = ? AND reset_token = ? AND reset_token_expires > NOW()',
      [email, otp]
    );

    if (users.length === 0) {
      return res.status(400).json({ error: 'Invalid or expired OTP' });
    }

    const user = users[0];
    // Generate a temporary token for the password reset
    const resetJwt = jwt.sign(
      { id: user.id, email: user.email, purpose: 'password_reset' },
      process.env.JWT_SECRET,
      { expiresIn: '10m' }
    );

    res.json({ message: 'OTP verified', reset_token: resetJwt });
  } catch (err) {
    console.error('Verify OTP error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ─────────────────────────────────────────────
// POST /api/auth/reset-password
// ─────────────────────────────────────────────
router.post('/reset-password', async (req, res) => {
  try {
    const { reset_token, new_password } = req.body;
    if (!reset_token || !new_password) {
      return res.status(400).json({ error: 'Reset token and new password are required' });
    }

    let decoded;
    try {
      decoded = jwt.verify(reset_token, process.env.JWT_SECRET);
    } catch {
      return res.status(401).json({ error: 'Invalid or expired reset token' });
    }

    if (decoded.purpose !== 'password_reset') {
      return res.status(401).json({ error: 'Invalid token purpose' });
    }

    const passwordHash = await bcrypt.hash(new_password, 12);
    await db.query(
      'UPDATE users SET password_hash = ?, reset_token = NULL, reset_token_expires = NULL WHERE id = ?',
      [passwordHash, decoded.id]
    );

    res.json({ message: 'Password reset successfully' });
  } catch (err) {
    console.error('Reset password error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ─────────────────────────────────────────────
// GET /api/auth/gyms (Public — for registration dropdown)
// ─────────────────────────────────────────────
router.get('/gyms', async (req, res) => {
  try {
    const [gyms] = await db.query(
      "SELECT id, name FROM gyms WHERE status = 'active' ORDER BY name"
    );
    res.json(gyms);
  } catch (err) {
    console.error('Get gyms error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ─────────────────────────────────────────────
// GET /api/auth/logo (Public — for login screen)
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
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
