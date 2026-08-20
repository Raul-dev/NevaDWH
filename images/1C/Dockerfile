FROM ubuntu:22.04

# Отключаем интерактивные диалоги при установке
ENV DEBIAN_FRONTEND=noninteractive

# Установка системных зависимостей, необходимых для работы инсталлятора и сервера 1С
RUN apt-get update && apt-get install -y --no-install-recommends \
    locales \
    libwebkit2gtk-4.0-37 \
    libfontconfig1 \
    libgsf-1-114 \
    libglib2.0-0 \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Настройка русской локали (критично для 1С)
RUN locale-gen ru_RU.UTF-8
ENV LANG=ru_RU.UTF-8
ENV LANGUAGE=ru_RU:ru
ENV LC_ALL=ru_RU.UTF-8

# Создаем пользователя и группу 1С заранее, так как инсталлятор в тихом режиме может их не создать
RUN groupadd -r grp1cv8 --gid=998 && useradd -r -g grp1cv8 --uid=998 usr1cv8

# 1. Копируем ZIP-архив с инсталлятором внутрь контейнера
COPY server64_8_3_27_2130.zip /tmp/1c.zip

# 2. Распаковываем его, делаем файл .run исполняемым и запускаем установку сервера 1С
RUN mkdir -p /tmp/1c-dist && \
    unzip /tmp/1c.zip -d /tmp/1c-dist && \
    chmod +x /tmp/1c-dist/setup-full-8.3.27.2130-x86_64.run && \
    /tmp/1c-dist/setup-full-8.3.27.2130-x86_64.run --mode unattended --enable-components server,ws && \
    rm -rf /tmp/1c-dist /tmp/1c.zip

# Создаем директорию для хранения лицензий и выставляем права
RUN mkdir -p /var/1C/licenses && chown -R usr1cv8:grp1cv8 /var/1C/licenses

# Переключаемся на пользователя 1С для безопасности
USER usr1cv8

# Точка запуска сервера 1С ( ragent )
CMD ["/opt/1cv8/x86_64/8.3.27.2130/ragent"]
