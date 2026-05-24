FROM python:3.12-slim

WORKDIR /app

COPY etc/mywebapp/requiraments.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py config.py migration.py ./
COPY templates/ ./templates/
COPY static/ ./static/
COPY etc/mywebapp/config.docker.json ./etc/mywebapp/config.json
COPY entrypoint.sh ./entrypoint.sh
RUN chmod +x entrypoint.sh

EXPOSE 8000

ENTRYPOINT ["./entrypoint.sh"]
