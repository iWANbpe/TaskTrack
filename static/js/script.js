async function checkHealth() 
{
    const aliveEl = document.getElementById('alive-status');
    const readyEl = document.getElementById('ready-status');

    try 
    {
        const aliveRes = await fetch('/health/alive');
        aliveEl.innerText = aliveRes.ok ? 'Alive' : 'Error';
        aliveEl.style.color = aliveRes.ok ? 'green' : 'red';

        const readyRes = await fetch('/health/ready');
        readyEl.innerText = readyRes.ok ? 'Online' : 'Offline';
        readyEl.style.color = readyRes.ok ? 'green' : 'red';
    } 
    catch (e) 
    {
        aliveEl.innerText = 'Not available';
        readyEl.innerText = 'Not available';
    }
}

document.addEventListener('DOMContentLoaded', checkHealth);

async function addTask() 
{
    const titleInput = document.getElementById('taskTitle');
    const title = titleInput.value;

    if (!title) return;

    const response = await fetch('/tasks', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ title: title })
    });

    if (response.ok) {
        const task = await response.json();
        const date = new Date(task.created_at).toLocaleString();
        
        const taskList = document.getElementById('taskList');
        const newTask = document.createElement('div');
        newTask.className = 'task';
        
        newTask.innerHTML = `
            <h3>${task.title}</h3>
            <small class="task-id">ID: ${task.id}</small>
            <small class="status-text">STATUS: ${task.status}</small>
            <small>CREATED AКT: ${date}</small>
        `;
                            
        taskList.prepend(newTask);
        titleInput.value = '';
    }
}

async function updateStatus() 
{
    const id = document.getElementById('taskIdInput').value;
    if (!id) return;

    const response = await fetch(`/tasks/${id}/status`, { method: 'POST' });
    const task = await response.json();

    document.querySelectorAll('.task').forEach(el => {
        if (el.querySelector('.task-id').innerText.includes(task.id)) 
        {
            el.querySelector('.status-text').innerText = `STATUS: ${task.status}`;
        }
    });
}

async function deleteDoneTasks() 
{
    await fetch('/tasks/delete/done', { method: 'POST' });
    location.reload();
}

async function deleteTaskById() 
{
    const taskId = document.getElementById('taskIdInput').value;
    await fetch(`/tasks/${taskId}/delete`, { method: 'POST' });
    location.reload();
}

async function deleteAllTasks() 
{
    if (confirm("Are you sure you want clear ALL tasks?")) 
    {
        await fetch('/tasks/delete/all', { method: 'POST' });
        location.reload();
    }
}
