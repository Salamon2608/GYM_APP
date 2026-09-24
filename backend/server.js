const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

// Initialize express
const app = express();
const PORT = process.env.PORT || 3000;

// Enable CORS
app.use(cors());

// Parse JSON body
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static uploads folder publicly
const uploadDir = process.env.UPLOAD_DIR || './uploads';
app.use('/uploads', express.static(path.join(__dirname, uploadDir)));

// Root endpoint status
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Mount Routes
app.use('/api/auth', require('./routes/auth.routes'));
app.use('/api/admin', require('./routes/admin.routes'));
app.use('/api/member', require('./routes/member.routes'));
app.use('/api/trainer', require('./routes/trainer.routes'));
app.use('/api/superadmin', require('./routes/superadmin.routes'));
app.use('/api/payments', require('./routes/payment.routes'));
app.use('/api/uploads', require('./routes/upload.routes'));

// Global Error Handler
app.use((err, req, res, next) => {
  console.error('Unhandled Error:', err);
  res.status(500).json({
    error: 'Internal Server Error',
    message: err.message,
  });
});

// Start Server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📂 Uploads folder served at http://0.0.0.0:${PORT}/uploads`);
});
