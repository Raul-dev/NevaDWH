FROM apache/airflow:3.3.0-python3.12

USER root

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    curl \
    gnupg2 \
    apt-transport-https \
    unixodbc-dev \
    freetds-dev \
    gcc \
    g++ \
  && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg \
  && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/debian/12/prod bookworm main" > /etc/apt/sources.list.d/mssql-release.list \
  && apt-get update \
  && ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql18 \
  && rm -rf /var/lib/apt/lists/*

USER airflow

RUN pip install --no-cache-dir pyodbc "pymssql>=2.3.2" psycopg2-binary \
  && pip install --no-cache-dir apache-airflow-providers-common-sql apache-airflow-providers-microsoft-mssql \
  && pip install --no-cache-dir pytest pytest-watcher

ENV AIRFLOW_HOME=/opt/airflow
