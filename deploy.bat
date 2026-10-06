@echo off
echo ===================================================
echo     TraceFit - Auto Deploy to GitHub and AWS
echo ===================================================
echo.

echo [1/3] Committing changes to Git...
git add .
set /p commitMsg="Enter commit message (or press enter for 'Auto deploy update'): "
if "%commitMsg%"=="" set commitMsg=Auto deploy update
git commit -m "%commitMsg%"
echo.

echo [2/3] Pushing changes to GitHub...
git push origin main
echo.

echo [3/3] Deploying to AWS Server...
echo This will pull the latest code and restart the backend on AWS.
ssh -i "tracefit-keytracefit-key.pem" ubuntu@54.152.143.110 "cd /var/www/tracefit && git pull origin main && cd backend && npm install && pm2 reload ecosystem.config.js"

echo.
echo ===================================================
echo                 DEPLOYMENT COMPLETE!
echo ===================================================
pause
