const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const db = require('../config/db');
const { authMiddleware } = require('../middleware/auth');
const { roleGuard } = require('../middleware/roleGuard');

router.use(authMiddleware);
router.use(roleGuard('trainer', 'admin', 'super_admin'));

function getGymId(req) {
  const gymId = req.user.gymId;
  if (!gymId) throw new Error('Gym ID is not associated with this account.');
  return gymId;
}

// ─────────────────────────────────────────────
// PROFILE & STATS
// ─────────────────────────────────────────────
router.get('/profile', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [trainers] = await db.query('SELECT * FROM trainers WHERE id = ? AND gym_id = ?', [req.user.id, gymId]);

    // Get dynamic rating
    const [[{ avg_rating }]] = await db.query(
      'SELECT COALESCE(AVG(rating), 5.0) as avg_rating FROM trainer_feedback WHERE trainer_id = ? AND gym_id = ?',
      [req.user.id, gymId]
    );

    const t = trainers[0] || {};
    res.json({ specialization: t.specialization || '', experience_years: t.experience_years || 0, bio: t.bio || '', rating: parseFloat(avg_rating) });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/profile', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { full_name, email, specialization, experience_years, bio } = req.body;

    await db.query('UPDATE users SET full_name = ? WHERE id = ?', [full_name, req.user.id]);
    if (email) await db.query('UPDATE users SET email = ? WHERE id = ?', [email, req.user.id]);

    // Upsert trainer
    const [existing] = await db.query('SELECT id FROM trainers WHERE id = ?', [req.user.id]);
    if (existing.length > 0) {
      await db.query(
        'UPDATE trainers SET specialization = ?, experience_years = ?, bio = ?, gym_id = ? WHERE id = ?',
        [specialization, experience_years, bio, gymId, req.user.id]
      );
    } else {
      await db.query(
        'INSERT INTO trainers (id, gym_id, specialization, experience_years, bio) VALUES (?, ?, ?, ?, ?)',
        [req.user.id, gymId, specialization, experience_years, bio]
      );
    }

    res.json({ message: 'Profile updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/stats', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [[{ member_count }]] = await db.query(
      'SELECT COUNT(*) as member_count FROM trainer_assignment WHERE trainer_id = ? AND gym_id = ?',
      [req.user.id, gymId]
    );
    const [[{ workout_count }]] = await db.query(
      'SELECT COUNT(*) as workout_count FROM workout_plans WHERE trainer_id = ? AND gym_id = ?',
      [req.user.id, gymId]
    );
    const [[{ diet_count }]] = await db.query(
      'SELECT COUNT(*) as diet_count FROM diet_plans WHERE trainer_id = ? AND gym_id = ?',
      [req.user.id, gymId]
    );
    const [[{ avg_rating }]] = await db.query(
      'SELECT COALESCE(AVG(rating), 5.0) as avg_rating FROM trainer_feedback WHERE trainer_id = ? AND gym_id = ?',
      [req.user.id, gymId]
    );

    res.json({ member_count, plan_count: workout_count + diet_count, rating: parseFloat(avg_rating) });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/feedback', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [rows] = await db.query(
      `SELECT tf.*, u.full_name as user_name
       FROM trainer_feedback tf
       JOIN users u ON tf.user_id = u.id
       WHERE tf.trainer_id = ? AND tf.gym_id = ?
       ORDER BY tf.created_at DESC`,
      [req.user.id, gymId]
    );

    const result = rows.map(r => ({ ...r, users: { full_name: r.user_name } }));
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// ASSIGNED MEMBERS
// ─────────────────────────────────────────────
router.get('/members', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [assignments] = await db.query(
      'SELECT member_id FROM trainer_assignment WHERE trainer_id = ? AND gym_id = ?',
      [req.user.id, gymId]
    );

    if (assignments.length === 0) return res.json([]);

    const memberIds = assignments.map(a => a.member_id);
    const placeholders = memberIds.map(() => '?').join(',');

    const [users] = await db.query(
      `SELECT u.id, u.email, u.full_name, u.phone, u.avatar_url, u.created_at
       FROM users u WHERE u.id IN (${placeholders}) AND u.gym_id = ?`,
      [...memberIds, gymId]
    );

    // Fetch assigned workouts and diets
    const [workouts] = await db.query(
      `SELECT user_id, plan_id FROM assigned_workouts 
       WHERE user_id IN (${placeholders}) AND gym_id = ?`,
      [...memberIds, gymId]
    );

    const [diets] = await db.query(
      `SELECT user_id, plan_id FROM assigned_diets 
       WHERE user_id IN (${placeholders}) AND gym_id = ?`,
      [...memberIds, gymId]
    );

    const result = users.map(u => {
      const userWorkouts = workouts.filter(w => w.user_id === u.id);
      const userDiets = diets.filter(d => d.user_id === u.id);
      return {
        member_id: u.id,
        users: {
          ...u,
          assigned_workouts: userWorkouts,
          assigned_diets: userDiets
        }
      };
    });

    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/members/:id', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const memberId = req.params.id;

    // User info
    const [users] = await db.query(
      'SELECT id, email, full_name, phone, avatar_url, created_at FROM users WHERE id = ? AND gym_id = ?',
      [memberId, gymId]
    );
    if (users.length === 0) return res.status(404).json({ error: 'Member not found' });

    // Health
    const [health] = await db.query('SELECT * FROM user_health WHERE user_id = ? AND gym_id = ?', [memberId, gymId]);
    const healthMap = health[0] || {};
    if (healthMap.weight_kg && healthMap.height_cm && healthMap.height_cm > 0) {
      const hm = healthMap.height_cm / 100;
      healthMap.bmi = healthMap.weight_kg / (hm * hm);
    }

    // Attendance
    const [attendance] = await db.query(
      'SELECT check_in FROM attendance WHERE user_id = ? AND gym_id = ? ORDER BY check_in DESC LIMIT 150',
      [memberId, gymId]
    );
    const uniqueDays = new Set();
    for (const r of attendance) {
      const d = new Date(r.check_in);
      uniqueDays.add(`${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`);
    }

    // Workout plan
    const [workouts] = await db.query(
      `SELECT wp.* FROM assigned_workouts aw
       JOIN workout_plans wp ON aw.plan_id = wp.id
       WHERE aw.user_id = ? AND aw.gym_id = ?
       ORDER BY aw.start_date DESC LIMIT 1`,
      [memberId, gymId]
    );

    // Diet plan
    const [diets] = await db.query(
      `SELECT dp.* FROM assigned_diets ad
       JOIN diet_plans dp ON ad.plan_id = dp.id
       WHERE ad.user_id = ? AND ad.gym_id = ?
       ORDER BY ad.start_date DESC LIMIT 1`,
      [memberId, gymId]
    );

    // BMI records
    const [bmiRecords] = await db.query(
      'SELECT * FROM bmi_records WHERE user_id = ? AND gym_id = ? ORDER BY recorded_at ASC',
      [memberId, gymId]
    );

    // Fetch memberships and plan names
    const [memberships] = await db.query(
      `SELECT um.*, mp.name as plan_name, mp.duration_months, mp.price
       FROM user_membership um
       LEFT JOIN membership_plans mp ON um.plan_id = mp.id
       WHERE um.user_id = ? AND um.gym_id = ?`,
      [memberId, gymId]
    );

    const userMemberships = memberships.map(m => ({
      id: m.id,
      user_id: m.user_id,
      plan_id: m.plan_id,
      gym_id: m.gym_id,
      start_date: m.start_date,
      end_date: m.end_date,
      status: m.status,
      created_at: m.created_at,
      membership_plans: m.plan_id ? {
        id: m.plan_id,
        name: m.plan_name,
        duration_months: m.duration_months,
        price: m.price
      } : null
    }));

    const userInfo = {
      ...users[0],
      user_membership: userMemberships
    };

    res.json({
      user_info: userInfo,
      health_metrics: healthMap,
      recent_visits_count: uniqueDays.size,
      attendance_records: attendance,
      workout_plan: workouts[0] || null,
      diet_plan: diets[0] || null,
      bmi_records: bmiRecords,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// WORKOUT PLANS
// ─────────────────────────────────────────────
router.get('/workout-plans', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [plans] = await db.query(
      `SELECT * FROM workout_plans WHERE gym_id = ? AND (trainer_id = ? OR trainer_id IS NULL)
       ORDER BY created_at DESC`,
      [gymId, req.user.id]
    );
    res.json(plans);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/workout-plans', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { name, goal, difficulty } = req.body;
    const id = uuidv4();

    await db.query(
      'INSERT INTO workout_plans (id, trainer_id, gym_id, name, goal, difficulty) VALUES (?, ?, ?, ?, ?, ?)',
      [id, req.user.id, gymId, name, goal, difficulty]
    );

    res.status(201).json({ id, message: 'Workout plan created' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/workout-plans/:id', async (req, res) => {
  try {
    const [plans] = await db.query('SELECT * FROM workout_plans WHERE id = ?', [req.params.id]);
    if (plans.length === 0) return res.status(404).json({ error: 'Not found' });

    const [items] = await db.query(
      'SELECT * FROM workout_plan_items WHERE plan_id = ? ORDER BY day_number, id',
      [req.params.id]
    );

    res.json({ ...plans[0], workout_plan_items: items });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/workout-plans/:id', async (req, res) => {
  try {
    const { name, goal } = req.body;
    await db.query('UPDATE workout_plans SET name = ?, goal = ? WHERE id = ?', [name, goal, req.params.id]);
    res.json({ message: 'Plan updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/workout-plans/:id', async (req, res) => {
  try {
    await db.query('DELETE FROM assigned_workouts WHERE plan_id = ?', [req.params.id]);
    await db.query('DELETE FROM workout_plans WHERE id = ?', [req.params.id]);
    res.json({ message: 'Plan deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/workout-plans/:id/items', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { items } = req.body;
    for (const item of items) {
      await db.query(
        `INSERT INTO workout_plan_items (id, plan_id, gym_id, day_number, exercise_name, sets_count, reps, video_url, notes)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [uuidv4(), req.params.id, gymId, item.day_number, item.exercise_name, item.sets || item.sets_count, item.reps, item.video_url || null, item.notes || null]
      );
    }
    res.status(201).json({ message: 'Items added' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/workout-plans/:id/items/:itemId', async (req, res) => {
  try {
    const { exercise_name, sets_count, reps } = req.body;
    await db.query(
      'UPDATE workout_plan_items SET exercise_name = ?, sets_count = ?, reps = ? WHERE id = ?',
      [exercise_name, sets_count, reps, req.params.itemId]
    );
    res.json({ message: 'Item updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/workout-plans/:id/items/:itemId', async (req, res) => {
  try {
    await db.query('DELETE FROM workout_plan_items WHERE id = ?', [req.params.itemId]);
    res.json({ message: 'Item deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/workout-plans/:id/assign', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { member_id } = req.body;

    const [existing] = await db.query(
      'SELECT id FROM assigned_workouts WHERE user_id = ? AND plan_id = ? AND gym_id = ?',
      [member_id, req.params.id, gymId]
    );
    if (existing.length > 0) return res.json({ status: 'already_assigned' });

    await db.query(
      `INSERT INTO assigned_workouts (id, user_id, plan_id, gym_id, start_date)
       VALUES (?, ?, ?, ?, ?)`,
      [uuidv4(), member_id, req.params.id, gymId, new Date().toISOString().split('T')[0]]
    );
    res.json({ status: 'assigned' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/workout-plans/:id/unassign', async (req, res) => {
  try {
    const { user_id } = req.body;
    await db.query('DELETE FROM assigned_workouts WHERE plan_id = ? AND user_id = ?', [req.params.id, user_id]);
    res.json({ message: 'Unassigned' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/workout-plans/:id/members', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [assignments] = await db.query('SELECT user_id FROM assigned_workouts WHERE plan_id = ? AND gym_id = ?', [req.params.id, gymId]);
    if (assignments.length === 0) return res.json([]);

    const userIds = assignments.map(a => a.user_id);
    const placeholders = userIds.map(() => '?').join(',');
    const [users] = await db.query(
      `SELECT id, full_name, email FROM users WHERE id IN (${placeholders}) AND gym_id = ?`,
      [...userIds, gymId]
    );
    res.json(users);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// DIET PLANS (similar structure)
// ─────────────────────────────────────────────
router.get('/diet-plans', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [plans] = await db.query(
      `SELECT * FROM diet_plans WHERE gym_id = ? AND (trainer_id = ? OR trainer_id IS NULL)
       ORDER BY created_at DESC`,
      [gymId, req.user.id]
    );
    res.json(plans);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/diet-plans', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { title, daily_calories } = req.body;
    const id = uuidv4();

    await db.query(
      'INSERT INTO diet_plans (id, trainer_id, gym_id, name, calories_target) VALUES (?, ?, ?, ?, ?)',
      [id, req.user.id, gymId, title, daily_calories]
    );

    res.status(201).json({ id, message: 'Diet plan created' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/diet-plans/:id', async (req, res) => {
  try {
    const [plans] = await db.query('SELECT * FROM diet_plans WHERE id = ?', [req.params.id]);
    if (plans.length === 0) return res.status(404).json({ error: 'Not found' });

    const [items] = await db.query('SELECT * FROM diet_plan_items WHERE plan_id = ? ORDER BY day_number, id', [req.params.id]);
    const parsed = items.map(i => ({ ...i, macros: typeof i.macros === 'string' ? JSON.parse(i.macros) : i.macros }));

    res.json({ ...plans[0], diet_plan_items: parsed });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/diet-plans/:id', async (req, res) => {
  try {
    const { title, daily_calories } = req.body;
    await db.query('UPDATE diet_plans SET name = ?, calories_target = ? WHERE id = ?', [title, daily_calories, req.params.id]);
    res.json({ message: 'Plan updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/diet-plans/:id', async (req, res) => {
  try {
    await db.query('DELETE FROM assigned_diets WHERE plan_id = ?', [req.params.id]);
    await db.query('DELETE FROM diet_plans WHERE id = ?', [req.params.id]);
    res.json({ message: 'Plan deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/diet-plans/:id/items', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { items } = req.body;
    for (const item of items) {
      await db.query(
        `INSERT INTO diet_plan_items (id, plan_id, gym_id, day_number, meal_time, food_item, calories, macros)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [uuidv4(), req.params.id, gymId, item.day_number, item.meal_time, item.food_item, item.calories || null, JSON.stringify(item.macros || null)]
      );
    }
    res.status(201).json({ message: 'Items added' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/diet-plans/:id/items/:itemId', async (req, res) => {
  try {
    const { food_item, meal_time, calories } = req.body;
    await db.query(
      'UPDATE diet_plan_items SET food_item = ?, meal_time = ?, calories = ? WHERE id = ?',
      [food_item, meal_time, calories || null, req.params.itemId]
    );
    res.json({ message: 'Item updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/diet-plans/:id/items/:itemId', async (req, res) => {
  try {
    await db.query('DELETE FROM diet_plan_items WHERE id = ?', [req.params.itemId]);
    res.json({ message: 'Item deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/diet-plans/:id/assign', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { member_id } = req.body;

    const [existing] = await db.query(
      'SELECT id FROM assigned_diets WHERE user_id = ? AND plan_id = ? AND gym_id = ?',
      [member_id, req.params.id, gymId]
    );
    if (existing.length > 0) return res.json({ status: 'already_assigned' });

    await db.query(
      `INSERT INTO assigned_diets (id, user_id, plan_id, gym_id, start_date)
       VALUES (?, ?, ?, ?, ?)`,
      [uuidv4(), member_id, req.params.id, gymId, new Date().toISOString().split('T')[0]]
    );
    res.json({ status: 'assigned' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/diet-plans/:id/unassign', async (req, res) => {
  try {
    const { user_id } = req.body;
    await db.query('DELETE FROM assigned_diets WHERE plan_id = ? AND user_id = ?', [req.params.id, user_id]);
    res.json({ message: 'Unassigned' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/diet-plans/:id/members', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [assignments] = await db.query('SELECT user_id FROM assigned_diets WHERE plan_id = ? AND gym_id = ?', [req.params.id, gymId]);
    if (assignments.length === 0) return res.json([]);

    const userIds = assignments.map(a => a.user_id);
    const placeholders = userIds.map(() => '?').join(',');
    const [users] = await db.query(
      `SELECT id, full_name, email FROM users WHERE id IN (${placeholders}) AND gym_id = ?`,
      [...userIds, gymId]
    );
    res.json(users);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// VIDEO LIBRARY
// ─────────────────────────────────────────────
router.get('/videos', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const [videos] = await db.query(
      'SELECT * FROM exercise_library WHERE gym_id = ? ORDER BY name',
      [gymId]
    );
    res.json(videos);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/videos', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const { name, muscle_group, difficulty, description, video_url } = req.body;

    // Check auto-approve setting
    let isApproved = false;
    const [settings] = await db.query(
      "SELECT value FROM app_settings WHERE `key` = 'auto_approve_trainer_videos' AND gym_id = ?",
      [gymId]
    );
    if (settings.length > 0) {
      let val = settings[0].value;
      if (typeof val === 'string') {
        try { val = JSON.parse(val); } catch (_) {}
      }
      if (val === true || val === 'true' || val === 1 || val === '1') {
        isApproved = true;
      }
    }

    await db.query(
      `INSERT INTO exercise_library (id, gym_id, name, muscle_group, difficulty, description, video_url, uploaded_by, is_approved)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [uuidv4(), gymId, name, muscle_group, difficulty, description || null, video_url || null, req.user.id, isApproved]
    );

    res.status(201).json({ message: 'Video submitted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/videos/:id', async (req, res) => {
  try {
    const { name, muscle_group, difficulty, description, video_url } = req.body;
    await db.query(
      'UPDATE exercise_library SET name = ?, muscle_group = ?, difficulty = ?, description = ?, video_url = ? WHERE id = ?',
      [name, muscle_group, difficulty, description || '', video_url || '', req.params.id]
    );
    res.json({ message: 'Video updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/videos/:id', async (req, res) => {
  try {
    await db.query('DELETE FROM exercise_library WHERE id = ?', [req.params.id]);
    res.json({ message: 'Video deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// MANUAL ATTENDANCE
// ─────────────────────────────────────────────
router.post('/attendance/:memberId', async (req, res) => {
  try {
    const gymId = getGymId(req);
    const memberId = req.params.memberId;
    const today = new Date();
    const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    const startOfDayStr = startOfDay.toISOString().slice(0, 19).replace('T', ' ');
    const nowStr = new Date().toISOString().slice(0, 19).replace('T', ' ');

    // Check if open check-in today
    const [existing] = await db.query(
      'SELECT id FROM attendance WHERE user_id = ? AND gym_id = ? AND check_in >= ? AND check_out IS NULL ORDER BY check_in DESC LIMIT 1',
      [memberId, gymId, startOfDayStr]
    );

    if (existing.length > 0) {
      // Check-out
      await db.query('UPDATE attendance SET check_out = ? WHERE id = ?', [nowStr, existing[0].id]);
      res.json({ status: 'checked_out' });
    } else {
      // Close orphaned sessions
      await db.query(
        'UPDATE attendance SET check_out = ? WHERE user_id = ? AND check_out IS NULL AND check_in < ?',
        [startOfDayStr, memberId, startOfDayStr]
      );

      // New check-in
      await db.query(
        "INSERT INTO attendance (id, user_id, gym_id, check_in, method) VALUES (?, ?, ?, ?, 'manual')",
        [uuidv4(), memberId, gymId, nowStr]
      );
      res.json({ status: 'checked_in' });
    }
  } catch (err) {
    console.error('Manual attendance error:', err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
