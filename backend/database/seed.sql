-- Seed database with default super_admin and active gym for tracefit
INSERT INTO gyms (id, name, address, status)
VALUES ('00000000-0000-0000-0000-000000000001', 'Tracefit Headquarters', '123 Fit St, Gymtown', 'active');

-- The password hash here is bcrypt('$2a$12$WgTAY29qiLH1zPnnTP0jVO1PXtKYgYzcAt7efBUWZiJFWytr.hcky') which stands for 'password'
INSERT INTO users (id, email, password_hash, full_name, role, gym_id, email_verified)
VALUES (
  '00000000-0000-0000-0000-000000000000',
  'superadmin@tracefit.com',
  '$2a$12$WgTAY29qiLH1zPnnTP0jVO1PXtKYgYzcAt7efBUWZiJFWytr.hcky',
  'Platform Owner',
  'super_admin',
  '00000000-0000-0000-0000-000000000001',
  TRUE
);
