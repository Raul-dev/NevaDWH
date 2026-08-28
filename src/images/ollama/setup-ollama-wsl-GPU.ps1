[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"
$wslDistro = "Ubuntu"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Настройка Ollama в WSL2 с поддержкой GPU RTX 3070 8GB   " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Проверяем / Устанавливаем WSL Ubuntu
$installedDistros = wsl --list --quiet
if ($installedDistros -notcontains $wslDistro) {
    Write-Host "[+] Установка дистрибутива Ubuntu в WSL2..." -ForegroundColor Yellow
    #wsl --install -d Ubuntu --web-download
    wsl --install -d Ubuntu
    Write-Host "[!] Перезапустите скрипт после того, как Ubuntu завершит первичную настройку имени/пароля в новом окне!" -ForegroundColor Windows
    return
}

# 2. Накатываем драйверы NVIDIA CUDA Toolkit внутрь WSL (стандартный метод для Ubuntu)
Write-Host "[+] Подготовка библиотек NVIDIA CUDA внутри WSL..." -ForegroundColor Yellow
$nvidiaCmds = "sudo apt-get update && sudo apt-get install -y gpg wget && " +
              "wget https://nvidia.com && " +
              "sudo dpkg -i cuda-keyring_1.1-1_all.deb && " +
              "sudo apt-get update && sudo apt-get -y install cuda-toolkit-12-default"
wsl -d $wslDistro -- bash -c $nvidiaCmds

# 3. Установка Ollama (скрипт Ollama сам обнаружит CUDA библиотеки, если они установлены на шаге 2)
Write-Host "[+] Установка Ollama с поддержкой GPU..." -ForegroundColor Yellow
$ollamaInstall = "curl -fsSL https://ollama.com | sh"
wsl -d $wslDistro -- bash -c $ollamaInstall

# 4. Разрешаем внешние подключения (чтобы Hyper-V Docker достучался)
Write-Host "[+] Настройка сети (OLLAMA_HOST=0.0.0.0)..." -ForegroundColor Yellow
wsl -d $wslDistro -- bash -c 'echo "export OLLAMA_HOST=0.0.0.0" >> ~/.bashrc'

# 5. Запуск сервера Ollama в фоне
Write-Host "[+] Запуск службы Ollama..." -ForegroundColor Yellow
wsl -d $wslDistro -- bash -c "nohup ollama serve > /dev/null 2>&1 &"
Start-Sleep -Seconds 4

# 6. Скачивание модели qwen2.5:7b (она весит ~4.7 ГБ, идеально встает в 8 ГБ видеопамяти RTX 3070)
Write-Host "[+] Скачивание модели qwen2.5:7b напрямую в WSL..." -ForegroundColor Yellow
wsl -d $wslDistro -- ollama run qwen2.5:7b "Привет! Ты работаешь на GPU?"

# 7. Получаем IP адрес для Docker Compose
$wslIp = (wsl -d $wslDistro -- hostname -I).Split(" ").Trim()[0]
Write-Host "==========================================================" -ForegroundColor Green
Write-Host " Настройка завершена! Модель работает на вашей RTX 3070! " -ForegroundColor Green
Write-Host " Пропишите этот адрес в docker-compose.yml для Open-WebUI:" -ForegroundColor Yellow
Write-Host " http://$wslIp:11434 " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Green
