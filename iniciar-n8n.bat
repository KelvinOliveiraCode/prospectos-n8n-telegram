@echo off
cd /d %~dp0
echo Iniciando n8n em http://localhost:5678
npx n8n start
pause
