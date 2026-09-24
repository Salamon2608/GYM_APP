import os
import json
import time
from datetime import datetime
import mysql.connector
from pyzk.zk import ZK

# --- CONFIGURATION (UPDATE THESE FOR PRODUCTION) ---
DB_HOST = os.environ.get("DB_HOST", "localhost")
DB_USER = os.environ.get("DB_USER", "root")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "")
DB_NAME = os.environ.get("DB_NAME", "tracefit_gym")
DB_PORT = int(os.environ.get("DB_PORT", 3306))

DEVICE_ID = os.environ.get("DEVICE_UUID", "YOUR_DEVICE_UUID_FROM_DB") # ID from essl_devices table
DEVICE_IP = os.environ.get("DEVICE_IP", "192.168.1.201") # IP address of the eSSL device
DEVICE_PORT = int(os.environ.get("DEVICE_PORT", 4370))

def get_db_connection():
    return mysql.connector.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        port=DB_PORT
    )

def fetch_and_push_logs(zk_client, last_record_time=None):
    """Fetches attendance from device and pushes to MySQL"""
    try:
        attendances = zk_client.get_attendance()
        
        if not attendances:
            return last_record_time

        print(f"[{datetime.now()}] Found {len(attendances)} total records on device.")
        newest_time = last_record_time

        # Filter and insert new records
        conn = get_db_connection()
        cursor = conn.cursor()
        count_pushed = 0

        for attendance in attendances:
            log_time = attendance.timestamp
            
            # Skip if we've already processed this
            if last_record_time and log_time <= last_record_time:
                continue

            # Check if this user_device_id has a mapping to a real user in the database
            # to keep relational integrity if needed, or simply log it.
            # Insert log query
            query = """
                INSERT INTO essl_logs (id, device_id, user_device_id, timestamp, status, synced_to_attendance)
                VALUES (UUID(), %s, %s, %s, %s, FALSE)
            """
            # pyzk status mappings: e.g., 0=CheckIn, 1=CheckOut
            status_str = "CheckIn" if attendance.status == 0 else "CheckOut"

            try:
                cursor.execute(query, (
                    DEVICE_ID,
                    int(attendance.user_id),
                    log_time.strftime('%Y-%m-%d %H:%M:%S'),
                    status_str
                ))
                conn.commit()
                count_pushed += 1
                
                # Keep track of the newest record we've seen
                if newest_time is None or log_time > newest_time:
                    newest_time = log_time

            except Exception as e:
                print(f"Error pushing log for user {attendance.user_id}: {e}")

        cursor.close()
        conn.close()

        print(f"[{datetime.now()}] Pushed {count_pushed} new logs to MySQL.")
        return newest_time

    except Exception as e:
        print(f"Error fetching attendance from device: {e}")
        return last_record_time

def run_middleware():
    print(f"Starting eSSL Sync Service for device at {DEVICE_IP}:{DEVICE_PORT}...")
    
    zk = ZK(DEVICE_IP, port=DEVICE_PORT, timeout=5)
    last_processed_time = None 
    
    # Fetch the latest timestamp from MySQL first
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        query = """
            SELECT timestamp FROM essl_logs 
            WHERE device_id = %s 
            ORDER BY timestamp DESC 
            LIMIT 1
        """
        cursor.execute(query, (DEVICE_ID,))
        row = cursor.fetchone()
        
        if row and row['timestamp']:
            # MySQL datetime fields are returned as naive datetime objects by mysql.connector
            last_processed_time = row['timestamp']
            print(f"Resuming sync from last known log time: {last_processed_time}")
            
        cursor.close()
        conn.close()
    except Exception as e:
        print(f"Warning: Could not fetch last log time from DB: {e}")

    while True:
        try:
            print(f"[{datetime.now()}] Connecting to device...")
            conn = zk.connect()
            conn.disable_device() # Good practice while reading
            
            last_processed_time = fetch_and_push_logs(conn, last_processed_time)
            
            conn.enable_device()
            conn.disconnect()
            
        except Exception as e:
            print(f"Connection error: {e}")
        finally:
             if 'conn' in locals() and conn:
                  try:
                      conn.disconnect()
                  except: pass

        # Poll every 10 seconds
        time.sleep(10)

if __name__ == "__main__":
    try:
        run_middleware()
    except KeyboardInterrupt:
        print("\nStopping middleware service.")
