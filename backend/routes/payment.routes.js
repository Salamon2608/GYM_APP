const express = require('express');
const router = express.Router();
const Razorpay = require('razorpay');
const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/db');
const { authMiddleware } = require('../middleware/auth');
const { sendPaymentReceipt } = require('../config/emailService');

// Helper to decrypt Razorpay secret (must match encryption mechanism if we want to support encrypted keys)
// Here, we use the AES key and IV configured in env or direct DB decryption logic.
const AES_KEY = process.env.AES_KEY || 'my32charultrasecurekeyforgym1234';
const AES_IV = process.env.AES_IV || 'my16charivstring';

function decrypt(encryptedBase64) {
  if (!encryptedBase64) return '';
  try {
    const key = Buffer.from(AES_KEY, 'utf8');
    const iv = Buffer.from(AES_IV, 'utf8');
    const encryptedText = Buffer.from(encryptedBase64, 'base64');
    const decipher = crypto.createDecipheriv('aes-256-cbc', key, iv);
    let decrypted = decipher.update(encryptedText);
    decrypted = Buffer.concat([decrypted, decipher.final()]);
    return decrypted.toString('utf8');
  } catch (err) {
    console.error('Decryption failed:', err);
    // Return direct string as fallback if it wasn't encrypted
    return encryptedBase64;
  }
}

// ─────────────────────────────────────────────
// GET /api/payments/plans
// ─────────────────────────────────────────────
router.get('/plans', authMiddleware, async (req, res) => {
  try {
    const [plans] = await db.query('SELECT * FROM platform_plans ORDER BY price ASC');
    res.json(plans);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// POST /api/payments/create-order
// ─────────────────────────────────────────────
router.post('/create-order', authMiddleware, async (req, res) => {
  try {
    const { plan_id, gym_id, type } = req.body;
    const user_id = req.user.id;

    let resolvedKeyId = process.env.RAZORPAY_KEY_ID;
    let resolvedKeySecret = process.env.RAZORPAY_KEY_SECRET;
    let amount = 0;
    let planName = '';

    if (type === 'gym_subscription') {
      // 1. Fetch platform plan
      const [plans] = await db.query('SELECT * FROM platform_plans WHERE id = ?', [plan_id]);
      if (plans.length === 0) {
        return res.status(404).json({ error: 'Platform plan not found' });
      }
      const platformPlan = plans[0];
      amount = Math.round(parseFloat(platformPlan.price) * 100); // in paise
      planName = platformPlan.name;

      // 2. Fetch Super Admin Razorpay Credentials from app_settings
      const [settings] = await db.query(
        `SELECT \`key\`, value FROM app_settings 
         WHERE \`key\` IN ('superadmin_razorpay_key', 'superadmin_razorpay_secret_encrypted')
         AND gym_id IS NULL
         ORDER BY updated_at DESC`
      );

      const keyEntry = settings.find(s => s.key === 'superadmin_razorpay_key');
      const secretEntry = settings.find(s => s.key === 'superadmin_razorpay_secret_encrypted');

      if (keyEntry && secretEntry) {
        resolvedKeyId = JSON.parse(keyEntry.value);
        resolvedKeySecret = decrypt(JSON.parse(secretEntry.value));
      }
    } else {
      // Default: member_subscription
      const [plans] = await db.query('SELECT * FROM membership_plans WHERE id = ?', [plan_id]);
      if (plans.length === 0) {
        return res.status(404).json({ error: 'Membership plan not found' });
      }
      const gymPlan = plans[0];
      amount = Math.round(parseFloat(gymPlan.price) * 100);
      planName = gymPlan.name;

      // 2. Fetch Gym-specific Razorpay Credentials
      if (gym_id) {
        const [gyms] = await db.query(
          'SELECT razorpay_key, razorpay_secret_encrypted FROM gyms WHERE id = ?',
          [gym_id]
        );
        if (gyms.length > 0 && gyms[0].razorpay_key && gyms[0].razorpay_secret_encrypted) {
          resolvedKeyId = gyms[0].razorpay_key;
          resolvedKeySecret = decrypt(gyms[0].razorpay_secret_encrypted);
        }
      }
    }

    let order;
    let isMockOrder = false;

    // Check if keys are dummy/test fallback keys
    const isDummyKey = !resolvedKeyId || 
                       resolvedKeyId === 'rzp_test_YOUR_KEY' || 
                       resolvedKeyId === 'sdfsdfdsf' || 
                       resolvedKeyId.includes('YOUR_KEY') ||
                       !resolvedKeySecret ||
                       resolvedKeySecret === 'your_razorpay_secret' ||
                       resolvedKeySecret === 'sdjfskdlskdjflksjdfksjflksjdlkslkd';

    if (isDummyKey) {
      isMockOrder = true;
    } else {
      try {
        const rzp = new Razorpay({
          key_id: resolvedKeyId,
          key_secret: resolvedKeySecret,
        });

        const receiptId = `receipt_${Date.now()}_${type === 'gym_subscription' ? 'gym' : 'mem'}`;
        order = await rzp.orders.create({
          amount,
          currency: 'INR',
          receipt: receiptId,
        });
      } catch (rzpErr) {
        console.warn('Razorpay order creation failed, falling back to mock order:', rzpErr.message);
        isMockOrder = true;
      }
    }

    if (isMockOrder) {
      const mockOrderId = `order_mock_${Date.now()}`;
      order = {
        id: mockOrderId,
        amount: amount,
        currency: 'INR',
      };
      resolvedKeyId = 'mock';
    }

    // Save pending payment record for member subscription
    if (type !== 'gym_subscription') {
      await db.query(
        `INSERT INTO payments (id, user_id, membership_plan_id, gym_id, amount, method, status, razorpay_order_id)
         VALUES (?, ?, ?, ?, ?, 'online', 'pending', ?)`,
        [uuidv4(), user_id, plan_id, gym_id || null, amount / 100, order.id]
      );
    }

    res.json({
      id: order.id,
      amount: order.amount,
      currency: order.currency,
      key_id: resolvedKeyId,
    });
  } catch (err) {
    console.error('Create order error:', err);
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// POST /api/payments/verify
// ─────────────────────────────────────────────
router.post('/verify', authMiddleware, async (req, res) => {
  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature, gym_id, type } = req.body;

    let resolvedKeySecret = process.env.RAZORPAY_KEY_SECRET;

    if (type === 'gym_subscription') {
      const [settings] = await db.query(
        `SELECT \`key\`, value FROM app_settings 
         WHERE \`key\` = 'superadmin_razorpay_secret_encrypted' AND gym_id IS NULL
         ORDER BY updated_at DESC LIMIT 1`
      );
      if (settings.length > 0) {
        resolvedKeySecret = decrypt(JSON.parse(settings[0].value));
      }
    } else {
      if (gym_id) {
        const [gyms] = await db.query(
          'SELECT razorpay_secret_encrypted FROM gyms WHERE id = ?',
          [gym_id]
        );
        if (gyms.length > 0 && gyms[0].razorpay_secret_encrypted) {
          resolvedKeySecret = decrypt(gyms[0].razorpay_secret_encrypted);
        }
      }
    }

    const isMock = razorpay_order_id && razorpay_order_id.startsWith('order_mock_');

    if (!isMock && !resolvedKeySecret) {
      return res.status(400).json({ error: 'Razorpay secret not configured' });
    }

    let isSignatureValid = false;
    if (isMock) {
      isSignatureValid = true;
    } else {
      const generatedSignature = crypto
        .createHmac('sha256', resolvedKeySecret)
        .update(`${razorpay_order_id}|${razorpay_payment_id}`)
        .digest('hex');
      isSignatureValid = (generatedSignature === razorpay_signature);
    }

    if (!isSignatureValid) {
      // Mark payment as failed if we have a record
      if (type !== 'gym_subscription') {
        await db.query(
          "UPDATE payments SET status = 'failed' WHERE razorpay_order_id = ?",
          [razorpay_order_id]
        );
      }
      return res.status(400).json({ success: false, error: 'Invalid payment signature' });
    }

    if (type !== 'gym_subscription') {
      // Generate receipt number
      const todayStr = new Date().toISOString().split('T')[0].replace(/-/g, '');
      const [[{ count }]] = await db.query(
        "SELECT COUNT(*) as count FROM payments WHERE DATE(created_at) = CURRENT_DATE() AND status = 'completed'"
      );
      const seq = (count + 1).toString().padStart(3, '0');
      const receiptNumber = `TF-${todayStr}-${seq}`;

      // Update payment record to completed
      await db.query(
        "UPDATE payments SET status = 'completed', transaction_id = ?, receipt_number = ? WHERE razorpay_order_id = ?",
        [razorpay_payment_id, receiptNumber, razorpay_order_id]
      );

      // Find the payment info to activate membership
      const [payments] = await db.query(
        'SELECT * FROM payments WHERE razorpay_order_id = ?',
        [razorpay_order_id]
      );

      if (payments.length > 0) {
        const payment = payments[0];
        
        // Get plan details
        const [[plan]] = await db.query('SELECT name, duration_months FROM membership_plans WHERE id = ?', [payment.membership_plan_id]);
        const durationMonths = plan ? plan.duration_months : 1;

        const startDate = new Date();
        const endDate = new Date(startDate);
        endDate.setMonth(endDate.getMonth() + durationMonths);

        // Deactivate old active membership
        await db.query(
          "UPDATE user_membership SET status = 'cancelled' WHERE user_id = ? AND gym_id = ?",
          [payment.user_id, payment.gym_id]
        );

        // Insert new active membership
        await db.query(
          `INSERT INTO user_membership (id, user_id, plan_id, gym_id, start_date, end_date, status)
           VALUES (?, ?, ?, ?, ?, ?, 'active')`,
          [uuidv4(), payment.user_id, payment.membership_plan_id, payment.gym_id, startDate.toISOString().split('T')[0], endDate.toISOString().split('T')[0]]
        );

        // Send email receipt
        try {
          const [[user]] = await db.query('SELECT email, full_name FROM users WHERE id = ?', [payment.user_id]);
          const [[gym]] = await db.query('SELECT name FROM gyms WHERE id = ?', [payment.gym_id]);
          
          if (user && gym && plan) {
            await sendPaymentReceipt(user.email, {
              receiptNumber,
              date: new Date(),
              gymName: gym.name,
              planName: plan.name,
              durationMonths: plan.duration_months,
              amount: payment.amount,
              paymentMethod: payment.method || 'online',
              transactionId: razorpay_payment_id || 'mock',
            });
          }
        } catch (emailErr) {
          console.error('Error sending receipt email:', emailErr);
        }
      }
    } else {
      const { plan_id } = req.body;
      if (!plan_id) throw new Error('Missing plan_id for gym subscription');

      // Fetch platform plan
      const [plans] = await db.query('SELECT * FROM platform_plans WHERE id = ?', [plan_id]);
      if (plans.length === 0) throw new Error('Platform plan not found');
      const plan = plans[0];

      const durationMonths = plan.duration_months;
      const amount = parseFloat(plan.price);
      const newEndDate = new Date();
      newEndDate.setDate(newEndDate.getDate() + (durationMonths * 30));

      // 1. Record subscription
      await db.query(
        `INSERT INTO gym_subscriptions (id, gym_id, amount, valid_from, valid_until, notes, recorded_by, payment_date)
         VALUES (?, ?, ?, NOW(), ?, ?, ?, NOW())`,
        [uuidv4(), gym_id, amount, newEndDate.toISOString().slice(0, 19).replace('T', ' '), `Online/Razorpay Payment for ${plan.name}. Order: ${razorpay_order_id}`, req.user.id]
      );

      // 2. Update gym status
      await db.query(
        "UPDATE gyms SET status = 'active', subscription_end_date = ? WHERE id = ?",
        [newEndDate.toISOString().slice(0, 19).replace('T', ' '), gym_id]
      );
    }

    res.json({ success: true });
  } catch (err) {
    console.error('Verify payment error:', err);
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
router.get('/receipt/:paymentId', authMiddleware, async (req, res) => {
  try {
    console.log(`[RECEIPT] Fetching receipt for payment ID: ${req.params.paymentId} by user: ${req.user.id} (${req.user.role})`);
    
    const [payments] = await db.query(
      `SELECT p.*, mp.name as plan_name, mp.duration_months, g.name as gym_name, g.address as gym_address, u.full_name as member_name, u.email as member_email
       FROM payments p
       LEFT JOIN membership_plans mp ON p.membership_plan_id = mp.id
       LEFT JOIN gyms g ON p.gym_id = g.id
       LEFT JOIN users u ON p.user_id = u.id
       WHERE p.id = ?`,
      [req.params.paymentId]
    );

    if (payments.length === 0) {
      console.log(`[RECEIPT] Receipt not found: ${req.params.paymentId}`);
      return res.status(404).json({ error: 'Receipt not found' });
    }

    const p = payments[0];
    
    // Auth check: member can only view their own receipt; admins can view any in their gym
    if (req.user.role === 'member' && p.user_id !== req.user.id) {
      console.log(`[RECEIPT] Access denied for member: ${req.user.id}`);
      return res.status(403).json({ error: 'Access denied' });
    }
    if (req.user.role === 'admin' && p.gym_id !== req.user.gymId) {
      console.log(`[RECEIPT] Access denied for admin: ${req.user.id}`);
      return res.status(403).json({ error: 'Access denied' });
    }

    console.log(`[RECEIPT] Sending successful receipt for: ${p.id}`);
    res.json({
      id: p.id,
      receipt_number: p.receipt_number,
      amount: p.amount,
      method: p.method,
      status: p.status,
      transaction_id: p.transaction_id,
      razorpay_order_id: p.razorpay_order_id,
      created_at: p.created_at,
      plan_name: p.plan_name,
      duration_months: p.duration_months,
      gym_name: p.gym_name,
      gym_address: p.gym_address,
      gym_phone: 'N/A', // Column does not exist in gyms table
      member_name: p.member_name,
      member_email: p.member_email,
    });
  } catch (err) {
    console.error(`[RECEIPT] Error fetching receipt:`, err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
