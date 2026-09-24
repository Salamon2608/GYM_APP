-- ============================================================
-- Migration: Add receipt_number column to payments table
-- Run this on your existing database to add receipt tracking
-- ============================================================

-- 1. Add receipt_number column
ALTER TABLE payments
  ADD COLUMN receipt_number VARCHAR(50) DEFAULT NULL AFTER razorpay_order_id;

-- 2. Add index for receipt lookups
CREATE INDEX idx_payments_receipt_number ON payments(receipt_number);

-- 3. Backfill existing completed payments with generated receipt numbers
-- Format: TF-YYYYMMDD-NNN (sequential per day)
SET @row_num = 0;
SET @prev_date = '';

UPDATE payments p
JOIN (
  SELECT
    id,
    DATE(created_at) as pay_date,
    @row_num := IF(DATE(created_at) = @prev_date, @row_num + 1, 1) as seq,
    @prev_date := DATE(created_at) as dummy
  FROM payments
  WHERE status = 'completed' AND receipt_number IS NULL
  ORDER BY created_at ASC
) ranked ON p.id = ranked.id
SET p.receipt_number = CONCAT(
  'TF-',
  DATE_FORMAT(ranked.pay_date, '%Y%m%d'),
  '-',
  LPAD(ranked.seq, 3, '0')
);
