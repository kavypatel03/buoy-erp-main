@echo off
echo Starting Backend Server...
start cmd /k "cd backend && npm run dev"

echo Starting Flutter Web...
start cmd /k "flutter run -d chrome"

echo Both servers are starting up in separate windows!
