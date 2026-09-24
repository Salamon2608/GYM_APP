# Gym Management App

A comprehensive Gym Management System built with Flutter and Supabase.

## Features Implemented (Member Phase)
- **Authentication**: Sign up, Login, Role-based redirects.
- **Dashboard**: Quick actions for Workout, Diet, Membership, Check-in.
- **Profile**: Health data, BMI calculator & history.
- **Membership**: View plans, Purchase flow (mock), Active status tracking.
- **Workouts**: View assigned workout plans, track progress.
- **Diet**: View assigned diet plans.
- **Attendance**: GPS-based Check-in/Check-out with geofencing.
- **Expiry Fallback**: Locks features for expired members.
- **Biometric Integration**: Syncs attendance from eSSL devices.

## Getting Started

### Prerequisites       
- Flutter SDK installed
- Android Emulator or Physical Device
- Supabase project (Credentials are pre-configured in `lib/core/constants/app_constants.dart`)
    
### How to Run
1.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```

2.  **Run the App**:
    ```bash
    flutter run
    ```

### Testing Guide

#### 1. Member Role (Default)
- **Register**: Create a new account. You will be redirected to the Member Dashboard.
- **Test Features**:
    - **Profile**: Set height/weight to see BMI.
    - **Membership**: Purchase a plan (mock payment) to unlock features.
    - **Check-in**: Use the "Check In" button (requires GPS).
    - **Expiry**: Wait for membership to expire or manually update `end_date` in Supabase to test locked features.

#### 2. Trainer / Admin Role
- Currently, new users are created as 'member' by default.
- To test Trainer or Admin dashboards:
    1.  Go to your Supabase Dashboard -> Table Editor -> `users` table.
    2.  Find your user row.
    3.  Change the `role` column to `'trainer'` or `'admin'`.
    4.  Restart the app or logout/login.

## Project Structure
- `lib/core`: Constants, Theme, Router, Services.
- `lib/features`: Feature-based folders (Auth, Member, Trainer, Admin).
- `database/schema.sql`: Complete database schema.
