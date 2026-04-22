import psycopg2
import json
import os

def run_migration():
    CONFIG_PATH = 'etc/mywebapp/config.json'

    with open(config_path, 'r') as f:
        config = json.load(f)

    try:
        conn = psycopg2.connect(**config['db'])
        cur = conn.cursor()
        print("Start of migration...")

        cur.execute('''
            CREATE TABLE IF NOT EXISTS tasks (
                id SERIAL PRIMARY KEY,
                title VARCHAR(255) NOT NULL,
                status VARCHAR(50),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        ''')
        
        conn.commit()
        print("Migration done successfully!")
        
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Exception: {e}")

if __name__ == '__main__':
    run_migration()
