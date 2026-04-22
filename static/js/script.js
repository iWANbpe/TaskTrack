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
            <small>ID: ${task.id}</small>
            <small>STATUS: ${task.status}</small>
            <small>CREATED AT: ${date}</small>
        `;
                            
        taskList.prepend(newTask);
        titleInput.value = '';
    }
}
