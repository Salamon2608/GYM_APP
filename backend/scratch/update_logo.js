const db = require('../config/db');
const { v4: uuidv4 } = require('uuid');

async function run() {
  try {
    const fileUrl = "http://localhost:3000/uploads/platform_logo.jpeg";
    
    // Update platform logo setting in the MySQL app_settings table
    const [result] = await db.query(
      `INSERT INTO app_settings (id, gym_id, \`key\`, value)
       VALUES (?, NULL, 'platform_logo_url', ?)
       ON DUPLICATE KEY UPDATE value = ?, updated_at = NOW()`,
      [uuidv4(), JSON.stringify(fileUrl), JSON.stringify(fileUrl)]
    );
    
    console.log("✅ Database logo URL updated successfully!", result);
    process.exit(0);
  } catch (err) {
    console.error("❌ Failed to update logo URL in database:", err);
    process.exit(1);
  }
}

run();
