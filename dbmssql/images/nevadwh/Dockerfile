FROM mcr.microsoft.com/dotnet/aspnet:8.0
USER app
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

COPY --chown=app:app publish/ .
ENTRYPOINT ["dotnet", "NevaDWH.dll"]
