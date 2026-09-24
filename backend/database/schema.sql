-- ============================================================
-- TRACEFIT GYM MANAGEMENT — MySQL Schema
-- Migrated from Supabase/PostgreSQL
-- ============================================================

-- Use the database
CREATE DATABASE IF NOT EXISTS tracefit_gym;
USE tracefit_gym;

-- ============================================================
-- GYMS (Platform-level)
-- ============================================================
CREATE TABLE gyms (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  name VARCHAR(255) NOT NULL,
  address TEXT,
  status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
  subscription_end_date DATETIME,
  razorpay_key VARCHAR(255),
  razorpay_secret_encrypted TEXT,
  logo_url TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- USERS & AUTH (merged auth.users + public.users)
-- ============================================================
CREATE TABLE users (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(255),
  role ENUM('member', 'trainer', 'admin', 'super_admin') DEFAULT 'member',
  phone VARCHAR(20),
  avatar_url TEXT,
  gym_id CHAR(36),
  email_verified BOOLEAN DEFAULT FALSE,
  reset_token VARCHAR(255),
  reset_token_expires DATETIME,
  refresh_token TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE SET NULL
);

CREATE TABLE user_health (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  user_id CHAR(36) UNIQUE NOT NULL,
  gym_id CHAR(36),
  age INT,
  gender ENUM('male', 'female', 'other'),
  height_cm FLOAT,
  weight_kg FLOAT,
  goal VARCHAR(100),
  blood_group VARCHAR(10),
  medical_conditions TEXT,
  allergies TEXT,
  experience_level VARCHAR(50),
  onboarding_completed BOOLEAN DEFAULT FALSE,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE SET NULL
);

CREATE TABLE bmi_records (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  user_id CHAR(36) NOT NULL,
  gym_id CHAR(36),
  bmi_value FLOAT NOT NULL,
  recorded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE SET NULL
);

-- ============================================================
-- MEMBERSHIP & PAYMENTS
-- ============================================================
CREATE TABLE membership_plans (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  gym_id CHAR(36),
  name VARCHAR(255) NOT NULL,
  duration_months INT NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  features JSON,
  is_active BOOLEAN DEFAULT TRUE,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE CASCADE
);

CREATE TABLE user_membership (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  user_id CHAR(36) NOT NULL,
  plan_id CHAR(36),
  gym_id CHAR(36),
  start_date DATE DEFAULT (CURRENT_DATE),
  end_date DATE NOT NULL,
  status ENUM('active', 'expired', 'cancelled') DEFAULT 'active',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (plan_id) REFERENCES membership_plans(id) ON DELETE SET NULL,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE SET NULL
);

CREATE TABLE payments (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  user_id CHAR(36) NOT NULL,
  membership_plan_id CHAR(36),
  gym_id CHAR(36),
  amount DECIMAL(10, 2) NOT NULL,
  method ENUM('cash', 'card', 'upi', 'online') DEFAULT 'cash',
  status ENUM('pending', 'completed', 'failed') DEFAULT 'pending',
  transaction_id VARCHAR(255),
  razorpay_order_id VARCHAR(255),
  receipt_number VARCHAR(50),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (membership_plan_id) REFERENCES membership_plans(id) ON DELETE SET NULL,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE SET NULL
);

-- ============================================================
-- TRAINERS & STAFF
-- ============================================================
CREATE TABLE trainers (
  id CHAR(36) PRIMARY KEY,
  gym_id CHAR(36),
  specialization VARCHAR(255),
  experience_years INT,
  bio TEXT,
  rating FLOAT DEFAULT 5.0,
  FOREIGN KEY (id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE SET NULL
);

CREATE TABLE trainer_assignment (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  trainer_id CHAR(36) NOT NULL,
  member_id CHAR(36) NOT NULL UNIQUE,
  gym_id CHAR(36),
  assigned_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (trainer_id) REFERENCES trainers(id) ON DELETE CASCADE,
  FOREIGN KEY (member_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE SET NULL
);

-- ============================================================
-- WORKOUT & DIET PLANS (TEMPLATES)
-- ============================================================
CREATE TABLE workout_plans (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  trainer_id CHAR(36),
  gym_id CHAR(36),
  name VARCHAR(255) NOT NULL,
  goal VARCHAR(255),
  difficulty ENUM('beginner', 'intermediate', 'advanced'),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (trainer_id) REFERENCES trainers(id) ON DELETE SET NULL,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE SET NULL
);

CREATE TABLE workout_plan_items (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  plan_id CHAR(36) NOT NULL,
  gym_id CHAR(36),
  day_number INT NOT NULL,
  exercise_name VARCHAR(255) NOT NULL,
  sets_count INT,
  reps INT,
  video_url TEXT,
  notes TEXT,
  FOREIGN KEY (plan_id) REFERENCES workout_plans(id) ON DELETE CASCADE,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE SET NULL
);

CREATE TABLE diet_plans (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  trainer_id CHAR(36),
  gym_id CHAR(36),
  name VARCHAR(255) NOT NULL,
  calories_target INT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (trainer_id) REFERENCES trainers(id) ON DELETE SET NULL,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE SET NULL
);

CREATE TABLE diet_plan_items (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  plan_id CHAR(36) NOT NULL,
  gym_id CHAR(36),
  day_number INT NOT NULL,
  meal_time VARCHAR(50),
  food_item VARCHAR(255) NOT NULL,
  calories INT,
  macros JSON,
  FOREIGN KEY (plan_id) REFERENCES diet_plans(id) ON DELETE CASCADE,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE SET NULL
);

-- ============================================================
-- ASSIGNMENTS & TRACKING
-- ============================================================
CREATE TABLE assigned_workouts (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  user_id CHAR(36) NOT NULL,
  plan_id CHAR(36) NOT NULL,
  assigned_by CHAR(36),
  gym_id CHAR(36),
  start_date DATE DEFAULT (CURRENT_DATE),
  is_active BOOLEAN DEFAULT TRUE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (plan_id) REFERENCES workout_plans(id) ON DELETE CASCADE,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE SET NULL
);

CREATE TABLE assigned_diets (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  user_id CHAR(36) NOT NULL,
  plan_id CHAR(36) NOT NULL,
  assigned_by CHAR(36),
  gym_id CHAR(36),
  start_date DATE DEFAULT (CURRENT_DATE),
  is_active BOOLEAN DEFAULT TRUE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (plan_id) REFERENCES diet_plans(id) ON DELETE CASCADE,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE SET NULL
);

CREATE TABLE workout_tracking (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  user_id CHAR(36) NOT NULL,
  plan_item_id CHAR(36),
  gym_id CHAR(36),
  is_completed BOOLEAN DEFAULT TRUE,
  weight_lifted FLOAT,
  completed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (plan_item_id) REFERENCES workout_plan_items(id) ON DELETE SET NULL,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE SET NULL
);

CREATE TABLE progress_tracking (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  user_id CHAR(36) NOT NULL,
  weight_kg FLOAT,
  chest_cm FLOAT,
  waist_cm FLOAT,
  photo_front_url TEXT,
  photo_side_url TEXT,
  recorded_at DATE DEFAULT (CURRENT_DATE),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ============================================================
-- EXERCISE LIBRARY & FEEDBACK
-- ============================================================
CREATE TABLE exercise_library (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  gym_id CHAR(36),
  name VARCHAR(255) NOT NULL,
  video_url TEXT,
  muscle_group VARCHAR(100),
  difficulty VARCHAR(50),
  description TEXT,
  uploaded_by CHAR(36),
  is_approved BOOLEAN DEFAULT FALSE,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE SET NULL,
  FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE trainer_feedback (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  user_id CHAR(36) NOT NULL,
  trainer_id CHAR(36) NOT NULL,
  gym_id CHAR(36),
  rating INT CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (trainer_id) REFERENCES trainers(id) ON DELETE CASCADE,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE SET NULL
);

CREATE TABLE complaints (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  user_id CHAR(36) NOT NULL,
  trainer_id CHAR(36),
  gym_id CHAR(36),
  subject VARCHAR(255) NOT NULL,
  description TEXT,
  status ENUM('pending', 'in_progress', 'resolved') DEFAULT 'pending',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (trainer_id) REFERENCES trainers(id) ON DELETE SET NULL,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE SET NULL
);

-- ============================================================
-- ATTENDANCE & HARDWARE
-- ============================================================
CREATE TABLE gym_locations (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  gym_id CHAR(36),
  name VARCHAR(255) NOT NULL,
  address TEXT,
  phone VARCHAR(20),
  email VARCHAR(255),
  latitude FLOAT NOT NULL,
  longitude FLOAT NOT NULL,
  radius_meters INT DEFAULT 100,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE CASCADE
);

CREATE TABLE attendance (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  user_id CHAR(36) NOT NULL,
  gym_id CHAR(36),
  check_in DATETIME,
  check_out DATETIME,
  date DATE DEFAULT (CURRENT_DATE),
  method ENUM('gps', 'biometric', 'manual') DEFAULT 'gps',
  status ENUM('present', 'absent', 'late') DEFAULT 'present',
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE SET NULL
);

CREATE TABLE essl_devices (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  name VARCHAR(255),
  ip_address VARCHAR(45) NOT NULL,
  port INT DEFAULT 4370,
  gym_location_id CHAR(36),
  is_active BOOLEAN DEFAULT TRUE,
  FOREIGN KEY (gym_location_id) REFERENCES gym_locations(id) ON DELETE SET NULL
);

CREATE TABLE essl_logs (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  device_id CHAR(36),
  user_device_id INT,
  timestamp DATETIME,
  status VARCHAR(20),
  synced_to_attendance BOOLEAN DEFAULT FALSE,
  FOREIGN KEY (device_id) REFERENCES essl_devices(id) ON DELETE SET NULL
);

CREATE TABLE essl_user_mapping (
  user_id CHAR(36) NOT NULL,
  device_user_id INT NOT NULL,
  PRIMARY KEY (user_id, device_user_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE doors (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  name VARCHAR(255),
  ip_address VARCHAR(45),
  controller_id CHAR(36),
  is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE door_access_logs (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  door_id CHAR(36),
  user_id CHAR(36),
  attempt_time DATETIME DEFAULT CURRENT_TIMESTAMP,
  access_granted BOOLEAN NOT NULL,
  reason VARCHAR(255),
  FOREIGN KEY (door_id) REFERENCES doors(id) ON DELETE SET NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ============================================================
-- AI & PERSONAL TRAINING
-- ============================================================
CREATE TABLE ai_requests (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  user_id CHAR(36) NOT NULL,
  goal TEXT,
  preferences JSON,
  status ENUM('pending', 'processing', 'completed', 'failed') DEFAULT 'pending',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE ai_plans (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  request_id CHAR(36),
  plan_json JSON,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (request_id) REFERENCES ai_requests(id) ON DELETE CASCADE
);

CREATE TABLE pt_packages (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  name VARCHAR(255) NOT NULL,
  session_count INT NOT NULL,
  price DECIMAL(10, 2),
  is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE pt_subscriptions (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  user_id CHAR(36) NOT NULL,
  package_id CHAR(36),
  sessions_remaining INT NOT NULL,
  status ENUM('active', 'completed', 'expired') DEFAULT 'active',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (package_id) REFERENCES pt_packages(id) ON DELETE SET NULL
);

CREATE TABLE pt_sessions (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  subscription_id CHAR(36),
  trainer_id CHAR(36),
  scheduled_at DATETIME,
  notes TEXT,
  status ENUM('scheduled', 'completed', 'cancelled', 'no_show') DEFAULT 'scheduled',
  FOREIGN KEY (subscription_id) REFERENCES pt_subscriptions(id) ON DELETE CASCADE,
  FOREIGN KEY (trainer_id) REFERENCES trainers(id) ON DELETE SET NULL
);

-- ============================================================
-- NOTIFICATIONS & REMINDERS
-- ============================================================
CREATE TABLE reminder_logs (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  user_id CHAR(36) NOT NULL,
  gym_id CHAR(36),
  type VARCHAR(50),
  sent_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE SET NULL
);

CREATE TABLE notifications (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  user_id CHAR(36) NOT NULL,
  gym_id CHAR(36),
  title VARCHAR(255),
  body TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE SET NULL
);

-- ============================================================
-- ADVERTISEMENTS
-- ============================================================
CREATE TABLE advertisements (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  gym_id CHAR(36),
  title VARCHAR(255) NOT NULL,
  image_url TEXT,
  target_segment ENUM('ALL', 'PREMIUM', 'EXPIRING', 'EXPIRED', 'INACTIVE') DEFAULT 'ALL',
  redirect_type VARCHAR(50),
  redirect_url TEXT,
  start_date DATETIME,
  end_date DATETIME,
  is_active BOOLEAN DEFAULT TRUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE CASCADE
);

CREATE TABLE ad_interactions (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  ad_id CHAR(36) NOT NULL,
  user_id CHAR(36) NOT NULL,
  gym_id CHAR(36),
  interaction_type ENUM('VIEW', 'CLICK') NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (ad_id) REFERENCES advertisements(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE SET NULL
);

-- ============================================================
-- LEADS
-- ============================================================
CREATE TABLE leads (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  gym_id CHAR(36) NOT NULL,
  full_name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  phone VARCHAR(20) NOT NULL,
  status ENUM('new', 'contacted', 'interested', 'trial', 'joined', 'lost') DEFAULT 'new',
  source VARCHAR(255),
  notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE CASCADE
);

-- ============================================================
-- APP SETTINGS
-- ============================================================
CREATE TABLE app_settings (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  gym_id CHAR(36),
  `key` VARCHAR(255) NOT NULL,
  value JSON,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY unique_gym_key (gym_id, `key`),
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE CASCADE
);

-- ============================================================
-- PLATFORM PLANS & GYM SUBSCRIPTIONS (Super Admin)
-- ============================================================
CREATE TABLE platform_plans (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price DECIMAL(10, 2) NOT NULL,
  duration_months INT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE gym_subscriptions (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  gym_id CHAR(36) NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  valid_from DATETIME NOT NULL,
  valid_until DATETIME NOT NULL,
  notes TEXT,
  recorded_by CHAR(36),
  payment_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE CASCADE,
  FOREIGN KEY (recorded_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ============================================================
-- CALORIE TRACKING
-- ============================================================
CREATE TABLE calorie_tracking (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  user_id CHAR(36) NOT NULL,
  gym_id CHAR(36),
  date DATE DEFAULT (CURRENT_DATE),
  meal_type VARCHAR(50),
  food_item VARCHAR(255),
  calories INT,
  protein FLOAT,
  carbs FLOAT,
  fats FLOAT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE SET NULL
);

-- ============================================================
-- INDEXES for performance
-- ============================================================
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_gym_id ON users(gym_id);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_attendance_user_id ON attendance(user_id);
CREATE INDEX idx_attendance_gym_id ON attendance(gym_id);
CREATE INDEX idx_attendance_check_in ON attendance(check_in);
CREATE INDEX idx_payments_user_id ON payments(user_id);
CREATE INDEX idx_payments_gym_id ON payments(gym_id);
CREATE INDEX idx_user_membership_user_id ON user_membership(user_id);
CREATE INDEX idx_user_membership_gym_id ON user_membership(gym_id);
CREATE INDEX idx_trainer_assignment_trainer ON trainer_assignment(trainer_id);
CREATE INDEX idx_trainer_assignment_gym ON trainer_assignment(gym_id);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_gym_id ON notifications(gym_id);
CREATE INDEX idx_workout_plans_trainer ON workout_plans(trainer_id);
CREATE INDEX idx_workout_plans_gym ON workout_plans(gym_id);
CREATE INDEX idx_assigned_workouts_user ON assigned_workouts(user_id);
CREATE INDEX idx_assigned_workouts_gym ON assigned_workouts(gym_id);
CREATE INDEX idx_complaints_gym ON complaints(gym_id);
CREATE INDEX idx_reminder_logs_gym ON reminder_logs(gym_id);
CREATE INDEX idx_advertisements_gym ON advertisements(gym_id);
CREATE INDEX idx_leads_gym_id ON leads(gym_id);
