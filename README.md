# TaskTrack: Система відстеження завдань

## 1. Індивідуальне завдання
Мій порядковий номер у списку групи: **13**.
Розрахунок варіантів:
* **V2**: (13 % 2) + 1 = **2**
* **V3**: (13 % 3) + 1 = **2**
* **V5**: (13 % 5) + 1 = **4**

**Опис:** Веб-програма для додавання та відстеження завдань з використанням PostgreSQL та Nginx.

## 2. Документація застосунку
### Призначення
TaskTrack — це веб-система для управління списком справ. Дозволяє користувачам додавати, переглядати та видаляти завдання.

### Налаштування середовища
Для роботи потрібна ОС Ubuntu.
1. Встановіть Python 3 та PostgreSQL: `sudo apt install python3 python3-venv postgresql`.
2. Створіть середовище: `python3 -m venv .venv`.
3. Встановіть залежності: `pip install -r etc/mywebapp/requiraments.txt`.

### Запуск
* **Локально:** `flask run`
* **Продакшн:** Сервіс автоматично налаштовується як `systemd` сервіс.

### API-ендпоінти
| Метод | Ендпоінт | Опис |
| :--- | :--- | :--- |
| `GET` | `/` | Отримання списку всіх завдань |
| `POST` | `/add` | Створення нового завдання |
| `POST` | `/toggle/<id>` | Зміна стану завдання (виконано/не виконано) |
| `DELETE` | `/delete/<id>` | Видалення завдання за ID |
| `DELETE` | `/delete/completed` | Видалення всіх виконаних завдань |
| `DELETE` | `/delete/all` | Видалення всіх завдань з бази даних |

## 3. Розгортання через Docker Compose
 
### Вимоги
* [Docker](https://docs.docker.com/get-docker/) 24+
* [Docker Compose](https://docs.docker.com/compose/) v2+
 
1. Клонуйте репозиторій (гілка lab_2):
    ```bash
    git clone -b lab_2 https://github.com/iWANbpe/TaskTrack.git
    cd TaskTrack
    ```
 
2. Запустіть усі сервіси:
    ```bash
    docker compose up -d
    ```
 
3. Застосунок доступний за адресою [http://localhost](http://localhost)

## 4. Тестування
1. **Перевірка сервісів:** `sudo systemctl status mywebapp` та `nginx`.
2. **Перевірка сокета:** `ls -l /home/student/TaskTrack/mywebapp.sock`.
3. **Curl-тест:** `curl -I http://localhost` має повернути `200 OK`.
4. **Перевірка БД:** `sudo -u postgres psql -d tasktrack_db -c "\dt"`.
