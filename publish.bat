@echo off
setlocal
cd /d "%~dp0"

where py >nul 2>nul
if %ERRORLEVEL%==0 (
  py -3 "%~dp0scripts\publish.py" %*
  exit /b %ERRORLEVEL%
)

where python >nul 2>nul
if %ERRORLEVEL%==0 (
  python "%~dp0scripts\publish.py" %*
  exit /b %ERRORLEVEL%
)

echo Python 3 was not found.
echo Install Python 3 and enable "Add Python to PATH", then run publish.bat again.
exit /b 1
