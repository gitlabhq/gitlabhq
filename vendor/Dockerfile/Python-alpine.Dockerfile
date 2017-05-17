FROM python:3.6-alpine

# Edit with mysql-client, postgresql-client, sqlite3, etc. for your needs.
# Or delete entirely if not needed.
RUN apk --no-cache add postgresql-client

WORKDIR /usr/src/app

COPY requirements.txt /usr/src/app/
RUN pip install --no-cache-dir -r requirements.txt

COPY . /usr/src/app

# For Django
EXPOSE 8000
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]

# For some other command
# CMD ["python", "app.py"]
