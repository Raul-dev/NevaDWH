# Скрипт автоматической настройки Ollama в WSL2 для интеграции с Open-WebUI
$ErrorActionPreference = "Stop"

# Имя дистрибутива WSL2, который мы будем использовать
$wslDistro = "Ubuntu-Ollama"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Настройка Ollama внутри WSL2 (Ubuntu) для Hyper-V Docker  " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Проверяем и устанавливаем дистрибутив Ubuntu, если его нет
$installedDistros = wsl --list --quiet
if ($installedDistros -notcontains $wslDistro) {
    Write-Host "[+] Установка нового дистрибутива WSL2: $wslDistro..." -ForegroundColor Yellow
    wsl --install -d Ubuntu --web-download
    # Переименовываем или используем стандартную Ubuntu, если кастомное имя не поддерживается старыми версиями
    $wslDistro = "Ubuntu"
} else {
    Write-Host "[*] Дистрибутив $wslDistro уже установлен." -ForegroundColor Green
}

# 2. Настройка окружения внутри WSL (Обновление и установка Ollama)
Write-Host "[+] Обновление пакетов и установка Ollama внутри WSL..." -ForegroundColor Yellow
$installCmd = "sudo apt-get update && sudo apt-get install -y curl && curl -fsSL https://ollama.com | sh"
wsl -d $wslDistro -- bash -c $installCmd

# 3. Настройка Ollama для прослушивания внешних сетевых запросов (из Hyper-V)
Write-Host "[+] Настройка сетевого доступа Ollama (OLLAMA_HOST=0.0.0.0)..." -ForegroundColor Yellow
$envConfigCmd = 'echo "export OLLAMA_HOST=0.0.0.0" >> ~/.bashrc'
wsl -d $wslDistro -- bash -c $envConfigCmd

# 4. Запуск службы Ollama в фоновом режиме внутри WSL
Write-Host "[+] Запуск сервера Ollama в фоне WSL..." -ForegroundColor Yellow
# Запускаем через nohup, чтобы процесс не умирал после закрытия скрипта
wsl -d $wslDistro -- bash -c "nohup ollama serve > /dev/null 2>&1 &"
Start-Sleep -Seconds 3

# 5. Скачивание модели ИИ напрямую в WSL
Write-Host "[+] Скачивание модели qwen2.5:7b внутрь WSL (это займет время)..." -ForegroundColor Yellow
wsl -d $wslDistro -- ollama run qwen2.5:7b "Привет, подтверди работу!"

# 6. Получение IP-адреса WSL для проброса в Docker
$wslIp = (wsl -d $wslDistro -- hostname -I).Split(" ")[0].Trim()
Write-Host "[*] Локальный IP виртуалки WSL2: $wslIp" -ForegroundColor Green

Write-Host "==========================================================" -ForegroundColor Green
Write-Host " Настройка успешно завершена! " -ForegroundColor Green
Write-Host " Теперь измените адрес Ollama в настройках Open-WebUI на: " -ForegroundColor Yellow
Write-Host " http://$wslIp:11434 " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Green
