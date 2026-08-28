# --- Этап 1: Сборка статических файлов ---
FROM node:22-alpine AS builder
WORKDIR /app

# Копируем файлы зависимостей
COPY package*.json ./
RUN npm ci

# Копируем исходный код проекта
COPY . .

# Собираем продакшн-версию сайта (создает папку dist)
RUN npm run build

# --- Этап 2: Продакшн веб-сервер ---
FROM nginx:alpine

# Копируем скомпилированный HTML из первого этапа в папку Nginx по умолчанию
COPY --from=builder /app/dist /usr/share/nginx/html

# Подменяем дефолтный конфиг Nginx нашим кастомным
COPY nginx-astro.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]