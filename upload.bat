@echo off
setlocal EnableExtensions
title Resume H5 - Upload to GitHub / Vercel
cd /d "%~dp0"

echo ============================================================
echo   Resume H5 - Upload to GitHub / Vercel
echo ============================================================
echo Folder: %CD%
echo.

git config --global --add safe.directory "%CD%" >nul 2>&1

where git >nul 2>&1
if errorlevel 1 (
  echo [ERROR] git not found in PATH.
  pause
  exit /b 2
)

if not exist "index.html" (
  echo [ERROR] index.html not found. Wrong folder.
  pause
  exit /b 2
)

if exist ".git\rebase-merge" goto fix_rebase
if exist ".git\rebase-apply" goto fix_rebase
goto after_rebase_check

:fix_rebase
echo [WARN] Git is in the middle of a rebase.
echo [WARN] Trying to abort the unfinished rebase automatically...
git rebase --abort
if errorlevel 1 goto rebase_fail
echo [OK] Rebase aborted. Continue upload.
echo.

:after_rebase_check
if not exist ".git" (
  echo [INIT] Initializing git repository...
  git init || goto fail
)

git branch -M main || goto fail

git remote get-url origin >nul 2>&1
if errorlevel 1 (
  git remote add origin https://github.com/tanbing-234/Resume-self.git || goto fail
) else (
  git remote set-url origin https://github.com/tanbing-234/Resume-self.git || goto fail
)

echo [1/4] Current status
echo ------------------------------------------------------------
git status --short
echo ------------------------------------------------------------
echo.

set /p "MSG=Commit message, Enter for default update: "
if "%MSG%"=="" set "MSG=update resume h5"

echo.
echo [2/4] Add files
git add -A || goto fail

echo.
echo [3/4] Commit if changed
git diff --cached --quiet
if errorlevel 1 (
  git commit -m "%MSG%" || goto fail
) else (
  echo No file changes to commit. Continue pushing current local commit.
)

echo.
echo [4/4] Push to GitHub
git push -u origin main
if not errorlevel 1 goto success

echo.
echo [WARN] Push was rejected or failed. Trying to pull remote changes first...
echo [WARN] Running: git pull --rebase origin main
git pull --rebase origin main
if errorlevel 1 goto pull_fail

echo.
echo [RETRY] Push again after rebase...
git push -u origin main
if errorlevel 1 goto push_fail

goto success

:success
echo.
echo ============================================================
echo   Upload succeeded. Vercel will redeploy automatically.
echo   GitHub: https://github.com/tanbing-234/Resume-self
echo   Site:   https://tyh-offer.icu
echo ============================================================
pause
exit /b 0

:rebase_fail
echo.
echo [ERROR] Could not abort rebase automatically.
echo Close other Git windows, then run this command manually in this folder:
echo   git rebase --abort
echo Then run upload.bat again.
pause
exit /b 1

:pull_fail
echo.
echo [ERROR] git pull --rebase failed.
echo If the message contains "Could not connect to server", fix the network or proxy first.
echo If there is a conflict, open the files Git mentions, fix them, then run:
echo   git add -A
echo   git rebase --continue
echo Then run upload.bat again.
pause
exit /b 1

:push_fail
echo.
echo [ERROR] git push failed again.
echo Check network connection and GitHub login/authentication.
pause
exit /b 1

:fail
echo.
echo [ERROR] Command failed. See message above.
pause
exit /b 1
