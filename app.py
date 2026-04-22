import os
import json
import psycopg2
from config import *
from psycopg2.extras import RealDictCursor
from flask import Flask, request, jsonify, render_template_string

app = Flask(__name__)

def load_config():
    with open(CONFIG_PATH, 'r') as f:
        return json.load(f)

config = load_config()

def get_db_connection():
    conn = psycopg2.connect(**config['db'])
    return conn

@app.route('/', methods=['GET'])
@app.route('/tasks', methods=['GET'])
def get_tasks():
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute('SELECT * FROM tasks ORDER BY created_at DESC;')
    tasks = cur.fetchall()
    cur.close()
    conn.close()

    if request.accept_mimetypes.best_match(['application/json', 'text/html']) == 'application/json':
        return jsonify(tasks)
    
    with open(HTML_TEMPLATE_PATH, 'r', encoding='utf-8') as f:
        html_content = f.read()
    
    return render_template_string(html_content, tasks=tasks)
    
@app.route('/tasks', methods=['POST'])
def add_task():
    data = request.get_json()
    
    if not data or 'title' not in data:
        return jsonify({"error": "Title is required"}), 400

    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    query = 'INSERT INTO tasks (title, status) VALUES (%s, %s) RETURNING id, title, status, created_at;'
    params = (data['title'], 'Not started')
    
    cur.execute(query, params)
    new_task = cur.fetchone()
    
    conn.commit()
    cur.close()
    conn.close()
    
    if new_task:
        return jsonify(new_task), 201
    else:
        return jsonify({"error": "Failed to insert task"}), 500

if __name__ == '__main__':
    app.run(
        host=config['web']['host'],
        port=config['web']['port'],
        debug=True
    )
