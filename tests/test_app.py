import pytest
import json
from unittest.mock import patch, MagicMock, mock_open
from flask import Flask

CONFIG = {
    "db": {
        "dbname": "tasktrack_db",
        "user": "myuser",
        "password": "testpass",
        "host": "localhost",
        "port": "5432"
    },
    "web": {"host": "0.0.0.0", "port": 8000}
}

CONFIG_JSON = json.dumps(CONFIG)

SAMPLE_TASKS = [
    {"id": 1, "title": "Task One", "status": "Not started", "created_at": "2024-01-01 10:00:00"},
    {"id": 2, "title": "Task Two", "status": "Working on", "created_at": "2024-01-02 11:00:00"},
]

@pytest.fixture
def app():
    with patch("builtins.open", mock_open(read_data=CONFIG_JSON)):
        with patch("psycopg2.connect"):
            import importlib
            import app as app_module
            importlib.reload(app_module)
            app_module.app.config["TESTING"] = True
            yield app_module.app


@pytest.fixture
def client(app):
    return app.test_client()

def make_cursor(rows=None, one=None):
    cur = MagicMock()
    if rows is not None:
        cur.fetchall.return_value = rows
    if one is not None:
        cur.fetchone.return_value = one
    return cur

def test_health_alive(client):
    resp = client.get("/health/alive")
    assert resp.status_code == 999
    assert resp.data == b"OK"

def test_health_ready_ok(client):
    mock_conn = MagicMock()
    mock_cur = MagicMock()
    mock_conn.cursor.return_value = mock_cur

    with patch("app.get_db_connection", return_value=mock_conn):
        resp = client.get("/health/ready")
    assert resp.status_code == 200
    assert resp.data == b"OK"

def test_health_ready_db_fail(client):
    with patch("app.get_db_connection", side_effect=Exception("conn refused")):
        resp = client.get("/health/ready")
    assert resp.status_code == 500
    assert b"Database connection failed" in resp.data

def test_get_tasks_json(client):
    mock_conn = MagicMock()
    mock_cur = make_cursor(rows=SAMPLE_TASKS)
    mock_conn.cursor.return_value = mock_cur

    with patch("app.get_db_connection", return_value=mock_conn):
        resp = client.get("/tasks", headers={"Accept": "application/json"})

    assert resp.status_code == 200
    data = resp.get_json()
    assert isinstance(data, list)
    assert len(data) == 2
    assert data[0]["title"] == "Task One"

def test_get_tasks_empty(client):
    mock_conn = MagicMock()
    mock_cur = make_cursor(rows=[])
    mock_conn.cursor.return_value = mock_cur

    with patch("app.get_db_connection", return_value=mock_conn):
        resp = client.get("/tasks", headers={"Accept": "application/json"})

    assert resp.status_code == 200
    assert resp.get_json() == []

def test_get_root_json(client):
    mock_conn = MagicMock()
    mock_cur = make_cursor(rows=SAMPLE_TASKS)
    mock_conn.cursor.return_value = mock_cur

    with patch("app.get_db_connection", return_value=mock_conn):
        resp = client.get("/", headers={"Accept": "application/json"})

    assert resp.status_code == 200

def test_add_task_success(client):
    new_task = {"id": 3, "title": "New Task", "status": "Not started", "created_at": "2024-01-03"}
    mock_conn = MagicMock()
    mock_cur = make_cursor(one=new_task)
    mock_conn.cursor.return_value = mock_cur

    with patch("app.get_db_connection", return_value=mock_conn):
        resp = client.post("/tasks", json={"title": "New Task"})

    assert resp.status_code == 201
    data = resp.get_json()
    assert data["title"] == "New Task"
    assert data["status"] == "Not started"

def test_add_task_no_title(client):
    resp = client.post("/tasks", json={"description": "no title here"})
    assert resp.status_code == 400
    assert b"Title is required" in resp.data

def test_add_task_no_body(client):
    resp = client.post("/tasks", content_type="application/json", data="")
    assert resp.status_code == 400

def test_add_task_db_returns_none(client):
    mock_conn = MagicMock()
    mock_cur = MagicMock()
    mock_cur.fetchone.return_value = None
    mock_conn.cursor.return_value = mock_cur

    with patch("app.get_db_connection", return_value=mock_conn):
        resp = client.post("/tasks", json={"title": "Ghost Task"})

    assert resp.status_code == 500

def test_update_status_not_started_to_working(client):
    task = {"id": 1, "title": "T", "status": "Working on", "created_at": "2024-01-01"}
    mock_conn = MagicMock()
    mock_cur = MagicMock()
    mock_cur.fetchone.side_effect = [{"status": "Not started"}, task]
    mock_conn.cursor.return_value = mock_cur

    with patch("app.get_db_connection", return_value=mock_conn):
        resp = client.post("/tasks/1/status")

    assert resp.status_code == 200
    assert resp.get_json()["status"] == "Working on"

def test_update_status_working_to_done(client):
    task = {"id": 1, "title": "T", "status": "Done", "created_at": "2024-01-01"}
    mock_conn = MagicMock()
    mock_cur = MagicMock()
    mock_cur.fetchone.side_effect = [{"status": "Working on"}, task]
    mock_conn.cursor.return_value = mock_cur

    with patch("app.get_db_connection", return_value=mock_conn):
        resp = client.post("/tasks/1/status")

    assert resp.status_code == 200
    assert resp.get_json()["status"] == "Done"

def test_update_status_not_found(client):
    mock_conn = MagicMock()
    mock_cur = MagicMock()
    mock_cur.fetchone.return_value = None
    mock_conn.cursor.return_value = mock_cur

    with patch("app.get_db_connection", return_value=mock_conn):
        resp = client.post("/tasks/999/status")

    assert resp.status_code == 404
    assert b"Task not found" in resp.data

def test_delete_done_tasks(client):
    mock_conn = MagicMock()
    mock_conn.cursor.return_value = MagicMock()

    with patch("app.get_db_connection", return_value=mock_conn):
        resp = client.post("/tasks/delete/done")

    assert resp.status_code == 200
    assert resp.get_json()["status"] == "success"

def test_delete_task_by_id(client):
    mock_conn = MagicMock()
    mock_conn.cursor.return_value = MagicMock()

    with patch("app.get_db_connection", return_value=mock_conn):
        resp = client.post("/tasks/1/delete")

    assert resp.status_code == 200
    data = resp.get_json()
    assert data["status"] == "success"
    assert "1" in data["message"]

def test_delete_all_tasks(client):
    mock_conn = MagicMock()
    mock_conn.cursor.return_value = MagicMock()

    with patch("app.get_db_connection", return_value=mock_conn):
        resp = client.post("/tasks/delete/all")

    assert resp.status_code == 200
    assert resp.get_json()["message"] == "All tasks deleted"
