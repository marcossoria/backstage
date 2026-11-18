FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py ./
COPY templates/ ./templates/
COPY static/ ./static/

RUN useradd --create-home --uid 10001 appuser
USER appuser
EXPOSE 8000
CMD ["gunicorn", "--workers", "1", "--threads", "2", "--bind", "0.0.0.0:8000", "--access-logfile", "-", "--error-logfile", "-", "app:app"]
