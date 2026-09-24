const db = require('../config/db');

async function test() {
  try {
    const [rows] = await db.query("SELECT * FROM app_settings WHERE `key` = 'platform_logo_url'");
    console.log("LOGO ROWS IN DB:", rows);
    process.exit(0);
  } catch (err) {
    console.error("ERROR:", err);
    process.exit(1);
  }
}

test();
