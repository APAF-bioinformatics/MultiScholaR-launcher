@echo off
setlocal enabledelayedexpansion

echo ========================================
echo MultiScholaR Launcher
echo ========================================
echo.

REM Get the directory where this batch file is located
set "LAUNCHER_DIR=%~dp0"

REM ========================================
REM Check Prerequisites
REM ========================================
echo Checking prerequisites...
echo.

REM Check for git
where git >nul 2>&1
if errorlevel 1 (
    echo ERROR: git is not installed or not in PATH.
    echo.
    echo Please install git from: https://git-scm.com/download/win
    echo.
    pause
    exit /b 1
)
echo [OK] git found

REM Check for pandoc (warning only)
where pandoc >nul 2>&1
if errorlevel 1 (
    echo [WARNING] pandoc not found - report generation will not work
    echo           Install from: https://pandoc.org/installing.html
) else (
    echo [OK] pandoc found
)

REM ========================================
REM Find R Installation
REM ========================================
echo.
echo Detecting R installation...

set "RSCRIPT_PATH="

REM First, try to find Rscript in PATH
where Rscript >nul 2>&1
if not errorlevel 1 (
    for /f "delims=" %%i in ('where Rscript') do (
        set "RSCRIPT_PATH=%%i"
        goto :found_r
    )
)

REM Check common Windows R installation locations
set "LOCALAPPDATA_R=%LOCALAPPDATA%\Programs\R"
if exist "%LOCALAPPDATA_R%" (
    for /f "delims=" %%d in ('dir /b /ad /o-n "%LOCALAPPDATA_R%" 2^>nul') do (
        set "RSCRIPT_CANDIDATE=%LOCALAPPDATA_R%\%%d\bin\Rscript.exe"
        if exist "!RSCRIPT_CANDIDATE!" (
            set "RSCRIPT_PATH=!RSCRIPT_CANDIDATE!"
            goto :found_r
        )
    )
)

REM Check Program Files
if exist "C:\Program Files\R" (
    for /f "delims=" %%d in ('dir /b /ad /o-n "C:\Program Files\R" 2^>nul') do (
        set "RSCRIPT_CANDIDATE=C:\Program Files\R\%%d\bin\Rscript.exe"
        if exist "!RSCRIPT_CANDIDATE!" (
            set "RSCRIPT_PATH=!RSCRIPT_CANDIDATE!"
            goto :found_r
        )
    )
)

REM Check Program Files (x86)
if exist "C:\Program Files (x86)\R" (
    for /f "delims=" %%d in ('dir /b /ad /o-n "C:\Program Files (x86)\R" 2^>nul') do (
        set "RSCRIPT_CANDIDATE=C:\Program Files (x86)\R\%%d\bin\Rscript.exe"
        if exist "!RSCRIPT_CANDIDATE!" (
            set "RSCRIPT_PATH=!RSCRIPT_CANDIDATE!"
            goto :found_r
        )
    )
)

REM R not found
echo.
echo ERROR: R is not installed or not found.
echo.
echo Please install R from: https://cran.r-project.org/
echo.
echo After installing R, also install Rtools from:
echo https://cran.r-project.org/bin/windows/Rtools/
echo.
pause
exit /b 1

:found_r
echo [OK] R found: !RSCRIPT_PATH!

REM ========================================
REM Check for Rtools (Windows only)
REM ========================================
echo.
echo Checking for Rtools...

set "RTOOLS_FOUND=0"

REM Check for gcc in PATH (indicates Rtools is installed and configured)
where gcc >nul 2>&1
if not errorlevel 1 (
    set "RTOOLS_FOUND=1"
    echo [OK] Rtools found (gcc in PATH)
    goto :rtools_done
)

REM Check common Rtools installation locations
REM Rtools 4.4 / 4.3 location
if exist "C:\rtools44\usr\bin\gcc.exe" (
    set "RTOOLS_FOUND=1"
    echo [OK] Rtools 4.4 found
    goto :rtools_done
)
if exist "C:\rtools43\usr\bin\gcc.exe" (
    set "RTOOLS_FOUND=1"
    echo [OK] Rtools 4.3 found
    goto :rtools_done
)
if exist "C:\rtools42\usr\bin\gcc.exe" (
    set "RTOOLS_FOUND=1"
    echo [OK] Rtools 4.2 found
    goto :rtools_done
)
if exist "C:\rtools40\usr\bin\gcc.exe" (
    set "RTOOLS_FOUND=1"
    echo [OK] Rtools 4.0 found
    goto :rtools_done
)

REM Rtools not found
echo.
echo ERROR: Rtools is not installed.
echo.
echo Rtools is required to compile R packages from source.
echo.
echo Please install Rtools from:
echo https://cran.r-project.org/bin/windows/Rtools/
echo.
echo Make sure to match the Rtools version to your R version:
echo   R 4.4.x -^> Rtools 4.4
echo   R 4.3.x -^> Rtools 4.3
echo   R 4.2.x -^> Rtools 4.2
echo.
pause
exit /b 1

:rtools_done
echo.

REM ========================================
REM Launch MultiScholaR
REM ========================================
echo ========================================
echo Starting MultiScholaR...
echo ========================================
echo.
echo This may take several minutes on first run while
echo packages are downloaded and installed.
echo.
echo Do not close this window.
echo.
echo Press any key to continue and select a branch...
pause >nul

REM Run the R launch script
"!RSCRIPT_PATH!" "%LAUNCHER_DIR%launch_multischolar.R"
set RSCRIPT_EXIT=!ERRORLEVEL!

echo.
echo ========================================
if !RSCRIPT_EXIT! neq 0 (
    echo MultiScholaR exited with code: !RSCRIPT_EXIT!
    echo There may have been an error. Check output above.
) else (
    echo MultiScholaR session ended.
)
echo ========================================
echo.
echo Press any key to close...
pause >nul

endlocal
