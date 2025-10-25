FROM python:3.9-slim

WORKDIR /app

COPY app.py .

EXPOSE 8000

CMD ["python3", "app.py"]