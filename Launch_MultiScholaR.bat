@echo off
setlocal enabledelayedexpansion

echo ========================================
echo MultiScholaR Launcher
echo ========================================
echo.

REM Get the directory where this batch file is located
set "LAUNCHER_DIR=%~dp0"
cd /d "%LAUNCHER_DIR%"

REM Default MultiScholaR installation path (Documents folder)
set "DOCUMENTS_DIR=%USERPROFILE%\Documents"
if not exist "%DOCUMENTS_DIR%" set "DOCUMENTS_DIR=%HOMEDRIVE%%HOMEPATH%\Documents"
set "MULTISCHOLAR_PATH=%DOCUMENTS_DIR%\MultiScholaR"

REM Detect R installation
echo Detecting R installation...
set "RSCRIPT_PATH="

REM First, try to find Rscript in PATH
where Rscript >nul 2>&1
if not errorlevel 1 (
    for /f "delims=" %%i in ('where Rscript') do set "RSCRIPT_PATH=%%i"
    echo Found Rscript in PATH: !RSCRIPT_PATH!
    goto :check_multischolar
)

REM Check common Windows R installation locations
set "LOCALAPPDATA_R=%LOCALAPPDATA%\Programs\R"
if exist "%LOCALAPPDATA_R%" (
    for /f "delims=" %%d in ('dir /b /ad /o-n "%LOCALAPPDATA_R%" 2^>nul') do (
        set "R_VERSION_DIR=%LOCALAPPDATA_R%\%%d"
        set "RSCRIPT_CANDIDATE=!R_VERSION_DIR!\bin\Rscript.exe"
        if exist "!RSCRIPT_CANDIDATE!" (
            set "RSCRIPT_PATH=!RSCRIPT_CANDIDATE!"
            echo Found Rscript: !RSCRIPT_PATH!
            goto :check_multischolar
        )
    )
)

REM Check Program Files
if exist "C:\Program Files\R" (
    for /f "delims=" %%d in ('dir /b /ad /o-n "C:\Program Files\R" 2^>nul') do (
        set "R_VERSION_DIR=C:\Program Files\R\%%d"
        set "RSCRIPT_CANDIDATE=!R_VERSION_DIR!\bin\Rscript.exe"
        if exist "!RSCRIPT_CANDIDATE!" (
            set "RSCRIPT_PATH=!RSCRIPT_CANDIDATE!"
            echo Found Rscript: !RSCRIPT_PATH!
            goto :check_multischolar
        )
    )
)

REM Check Program Files (x86)
if exist "C:\Program Files (x86)\R" (
    for /f "delims=" %%d in ('dir /b /ad /o-n "C:\Program Files (x86)\R" 2^>nul') do (
        set "R_VERSION_DIR=C:\Program Files (x86)\R\%%d"
        set "RSCRIPT_CANDIDATE=!R_VERSION_DIR!\bin\Rscript.exe"
        if exist "!RSCRIPT_CANDIDATE!" (
            set "RSCRIPT_PATH=!RSCRIPT_CANDIDATE!"
            echo Found Rscript: !RSCRIPT_PATH!
            goto :check_multischolar
        )
    )
)

echo ERROR: Could not detect R installation.
echo Please ensure R is installed.
pause
exit /b 1

:check_multischolar
echo.
echo Checking for MultiScholaR installation...

REM Check if MultiScholaR directory exists
if exist "!MULTISCHOLAR_PATH!" (
    echo MultiScholaR found at: !MULTISCHOLAR_PATH!
    goto :update_repo
)

REM MultiScholaR not found - offer to install
echo.
echo MultiScholaR not found at: !MULTISCHOLAR_PATH!
echo.
echo Would you like to install MultiScholaR now?
echo This will clone the repository from GitHub.
echo.
choice /C YN /M "Install MultiScholaR"
if errorlevel 2 (
    echo Installation cancelled.
    pause
    exit /b 1
)

REM Check for git
echo.
echo Checking for git...
where git >nul 2>&1
if errorlevel 1 (
    echo ERROR: git is not available.
    echo Please install git from https://git-scm.com/download/win
    pause
    exit /b 1
)

REM Clone the repository
echo.
echo Installing MultiScholaR...
echo Cloning repository to: !MULTISCHOLAR_PATH!
git clone -b GUI https://github.com/APAF-bioinformatics/MultiScholaR.git "!MULTISCHOLAR_PATH!"
if errorlevel 1 (
    echo ERROR: Failed to clone repository.
    echo Please check your internet connection and try again.
    pause
    exit /b 1
)
echo MultiScholaR installed successfully!

:update_repo
echo.
echo ========================================
echo Updating MultiScholaR repository...
echo ========================================
cd /d "!MULTISCHOLAR_PATH!"
git pull origin GUI 2>nul
if errorlevel 1 (
    echo.
    echo WARNING: Failed to update repository via git pull.
    echo This may be due to network issues or local changes.
    echo MultiScholaR will continue with the existing local version.
    echo.
) else (
    echo Repository updated successfully.
)
echo.

REM Return to launcher directory
cd /d "%LAUNCHER_DIR%"

REM Check for Pandoc
echo ========================================
echo Checking for Pandoc...
echo ========================================
where pandoc >nul 2>&1
if errorlevel 1 (
    echo WARNING: Pandoc NOT found in PATH
    echo.
    echo Pandoc is required for generating reports in MultiScholaR.
    echo Without Pandoc, you can still use MultiScholaR for all analysis
    echo steps, but report generation will fail.
    echo.
    echo Download from: https://pandoc.org/installing.html
    echo.
    echo MultiScholaR will continue to launch...
    echo.
) else (
    for /f "tokens=*" %%i in ('pandoc --version ^| findstr /R "^pandoc"') do set PANDOC_VERSION=%%i
    echo Pandoc found - %PANDOC_VERSION%
    echo.
)

REM Launch R script
echo ========================================
echo Launching MultiScholaR...
echo ========================================
echo.

REM Use the existing launch_multischolar.R script and pass the path as argument
if exist "%LAUNCHER_DIR%launch_multischolar.R" (
    "%RSCRIPT_PATH%" "%LAUNCHER_DIR%launch_multischolar.R" "!MULTISCHOLAR_PATH!"
    set RSCRIPT_EXIT_CODE=%ERRORLEVEL%
) else (
    echo ERROR: launch_multischolar.R not found in launcher directory
    echo Expected at: %LAUNCHER_DIR%launch_multischolar.R
    set RSCRIPT_EXIT_CODE=1
)

echo.
echo ========================================
if %RSCRIPT_EXIT_CODE% neq 0 (
    echo MultiScholaR finished with exit code: %RSCRIPT_EXIT_CODE%
    echo There may have been an error. Check the output above.
) else (
    echo MultiScholaR completed successfully
)
echo ========================================

echo.
echo Press any key to exit...
pause >nul

endlocal
