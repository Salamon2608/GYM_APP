const nodemailer = require('nodemailer');
require('dotenv').config();

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp.gmail.com',
  port: parseInt(process.env.SMTP_PORT || '587'),
  secure: process.env.SMTP_PORT === '465', // true for 465, false for other ports
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

function isSmtpConfigured() {
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;
  return user && pass && user !== 'your_email@gmail.com' && pass !== 'your_app_password' && user.trim() !== '' && pass.trim() !== '';
}

async function sendPaymentReceipt(toEmail, receiptData) {
  if (!isSmtpConfigured()) {
    console.warn('⚠️ SMTP Email not fully configured. Skipping receipt email sending.');
    return false;
  }

  const {
    receiptNumber,
    date,
    gymName,
    planName,
    durationMonths,
    amount,
    paymentMethod,
    transactionId,
  } = receiptData;

  const htmlContent = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Payment Receipt - TRACEFIT</title>
      <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #121212; color: #e0e0e0; margin: 0; padding: 20px; }
        .container { max-width: 600px; margin: 0 auto; background-color: #1e1e1e; border-radius: 12px; border: 1px solid #2d2d2d; padding: 30px; }
        .header { text-align: center; border-bottom: 2px solid #ff6d00; padding-bottom: 20px; }
        .logo { font-size: 28px; font-weight: bold; color: #ff6d00; letter-spacing: 1px; }
        .title { font-size: 18px; color: #a0a0a0; margin-top: 5px; }
        .receipt-info { margin: 20px 0; font-size: 14px; color: #a0a0a0; border-bottom: 1px dashed #2d2d2d; padding-bottom: 15px; }
        .details-table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        .details-table th { text-align: left; color: #ff6d00; font-size: 14px; padding-bottom: 10px; border-bottom: 1px solid #2d2d2d; }
        .details-table td { padding: 12px 0; font-size: 15px; border-bottom: 1px solid #1f1f1f; }
        .total-row td { font-weight: bold; font-size: 18px; color: #ffffff; padding-top: 15px; border-bottom: none; }
        .payment-meta { background-color: #151515; border-radius: 8px; padding: 15px; margin: 20px 0; font-size: 13px; color: #888888; border-left: 3px solid #ff6d00; }
        .footer { text-align: center; font-size: 12px; color: #666666; margin-top: 30px; border-top: 1px solid #2d2d2d; padding-top: 20px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <div class="logo">TRACEFIT</div>
          <div class="title">Payment Receipt</div>
        </div>
        <div class="receipt-info">
          <table style="width: 100%;">
            <tr>
              <td>
                <strong>Receipt No:</strong> ${receiptNumber}<br>
                <strong>Date:</strong> ${new Date(date).toLocaleDateString('en-IN', { year: 'numeric', month: 'long', day: 'numeric' })}
              </td>
              <td style="text-align: right;">
                <strong>Gym:</strong> ${gymName}
              </td>
            </tr>
          </table>
        </div>
        <table class="details-table">
          <thead>
            <tr>
              <th>Description</th>
              <th style="text-align: right;">Amount</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>
                <strong>${planName} Membership</strong><br>
                <span style="font-size: 12px; color: #888888;">Duration: ${durationMonths} month(s)</span>
              </td>
              <td style="text-align: right; vertical-align: top;">₹${amount}</td>
            </tr>
            <tr class="total-row">
              <td>Total Paid</td>
              <td style="text-align: right;">₹${amount}</td>
            </tr>
          </tbody>
        </table>
        <div class="payment-meta">
          <strong>Transaction Details:</strong><br>
          Payment Method: ${paymentMethod.toUpperCase()}<br>
          Transaction ID: ${transactionId}
        </div>
        <div class="footer">
          Thank you for choosing TRACEFIT!<br>
          If you have any questions, please contact your gym administration.<br>
          <span style="font-size: 10px; margin-top: 10px; display: block;">This is an automatically generated email. Please do not reply.</span>
        </div>
      </div>
    </body>
    </html>
  `;

  try {
    const info = await transporter.sendMail({
      from: process.env.SMTP_FROM || 'TRACEFIT <noreply@tracefit.com>',
      to: toEmail,
      subject: `Payment Receipt: ${receiptNumber} - TRACEFIT`,
      html: htmlContent,
    });
    console.log('✅ Receipt email sent successfully:', info.messageId);
    return true;
  } catch (error) {
    console.error('❌ Failed to send receipt email:', error);
    return false;
  }
}

module.exports = { sendPaymentReceipt };
