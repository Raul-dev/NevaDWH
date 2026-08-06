FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*
USER $APP_UID
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

COPY --chown=$APP_UID:$APP_UID publish/ .
ENTRYPOINT ["dotnet", "MQ.WebService.dll"]
