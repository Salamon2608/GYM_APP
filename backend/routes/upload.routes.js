const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/db');
const { authMiddleware } = require('../middleware/auth');

// Setup upload directory
const uploadDir = process.env.UPLOAD_DIR || './uploads';
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Multer storage configuration
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = `${Date.now()}-${uuidv4()}`;
    cb(null, `${uniqueSuffix}${path.extname(file.originalname)}`);
  },
});

// File filter (accept images only)
const fileFilter = (req, file, cb) => {
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new Error('Only images are allowed!'), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: parseInt(process.env.MAX_FILE_SIZE || '10485760') }, // default 10MB
});

// Helper: build public file URL
function getPublicUrl(req, filename) {
  const protocol = req.protocol;
  const host = req.get('host');
  return `${protocol}://${host}/uploads/${filename}`;
}

// ─────────────────────────────────────────────
// POST /api/uploads/gym-logo
// ─────────────────────────────────────────────
router.post('/gym-logo', authMiddleware, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    const gymId = req.user.gymId;
    if (!gymId) {
      return res.status(400).json({ error: 'User is not associated with a gym' });
    }

    const fileUrl = getPublicUrl(req, req.file.filename);

    // Update gym table
    await db.query('UPDATE gyms SET logo_url = ? WHERE id = ?', [fileUrl, gymId]);

    res.json({ publicUrl: fileUrl });
  } catch (err) {
    console.error('Gym logo upload error:', err);
    res.status(500).json({ error: err.message });
  }
});
// ─────────────────────────────────────────────
// POST /api/uploads/ad-image
// ─────────────────────────────────────────────
router.post('/ad-image', authMiddleware, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    const fileUrl = getPublicUrl(req, req.file.filename);
    res.json({ publicUrl: fileUrl });
  } catch (err) {
    console.error('Ad image upload error:', err);
    res.status(500).json({ error: err.message });
  }
});
// ─────────────────────────────────────────────
// POST /api/uploads/avatar
// ─────────────────────────────────────────────
router.post('/avatar', authMiddleware, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    const fileUrl = getPublicUrl(req, req.file.filename);

    // Update users table
    await db.query('UPDATE users SET avatar_url = ? WHERE id = ?', [fileUrl, req.user.id]);

    res.json({ publicUrl: fileUrl });
  } catch (err) {
    console.error('Avatar upload error:', err);
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// POST /api/uploads/platform-logo (Super Admin only)
// ─────────────────────────────────────────────
router.post('/platform-logo', authMiddleware, upload.single('image'), async (req, res) => {
  try {
    if (req.user.role !== 'super_admin') {
      return res.status(403).json({ error: 'Forbidden' });
    }

    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    const fileUrl = getPublicUrl(req, req.file.filename);

    // Update platform logo setting
    await db.query(
      `INSERT INTO app_settings (id, gym_id, \`key\`, value)
       VALUES (?, NULL, 'platform_logo_url', ?)
       ON DUPLICATE KEY UPDATE value = ?, updated_at = NOW()`,
      [uuidv4(), JSON.stringify(fileUrl), JSON.stringify(fileUrl)]
    );

    res.json({ publicUrl: fileUrl });
  } catch (err) {
    console.error('Platform logo upload error:', err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
