@echo off
setlocal enabledelayedexpansion

echo ========================================
echo MultiScholaR Launcher
echo ========================================
echo.

REM Get the directory where this batch file is located
set "LAUNCHER_DIR=%~dp0"

REM Check for flags
set "LOCAL_FLAG="
:parse_args
if "%~1"=="" goto :args_done
if "%~1"=="--local" set "LOCAL_FLAG=--local"
shift
goto :parse_args
:args_done
rem Need to shift back if we want to use positionals later, but here we just need the flag

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
REM Rtools 4.5 / 4.4 / 4.3 location
if exist "C:\rtools45\usr\bin\gcc.exe" (
    set "RTOOLS_FOUND=1"
    echo [OK] Rtools 4.5 found
    goto :rtools_done
)
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
echo   R 4.5.x -^> Rtools 4.5
echo   R 4.4.x -^> Rtools 4.4
echo   R 4.3.x -^> Rtools 4.3
echo   R 4.2.x -^> Rtools 4.2
echo.
pause
exit /b 1

:rtools_done
echo.

REM ========================================
REM Branch Selection
REM ========================================
if "%LOCAL_FLAG%"=="" (
    echo ========================================
    echo Branch/Version Selection
    echo ========================================
    echo.

    set "MULTISCHOLAR_REPO=APAF-bioinformatics/MultiScholaR"
    set "DEFAULT_BRANCH=main"
    set "PERSISTENCE_FILE=%LAUNCHER_DIR%.last_branch"

    REM Try to detect remote default branch using git
    for /f "usebackq tokens=*" %%a in (`git ls-remote --symref "https://github.com/APAF-bioinformatics/MultiScholaR.git" HEAD 2^>nul ^| findstr "^ref: refs/heads/"`) do (
        set "LINE=%%a"
        set "DEFAULT_BRANCH=!LINE:ref: refs/heads/=!"
        set "DEFAULT_BRANCH=!DEFAULT_BRANCH:	HEAD=!"
    )

    REM Load last selected branch if exists
    set "LAST_SELECTED="
    if exist "%PERSISTENCE_FILE%" (
        set /p LAST_SELECTED=<"%PERSISTENCE_FILE%"
    )

    set "SELECTED_BRANCH="

    REM Try to fetch branches from GitHub using PowerShell for reliable parsing
    echo Fetching available branches...
    set "BRANCH_COUNT=0"

    REM Use PowerShell to get and parse branch names
    for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "$ErrorActionPreference='SilentlyContinue'; git ls-remote --heads 'https://github.com/APAF-bioinformatics/MultiScholaR.git' 2>$null | ForEach-Object { ($_ -split '\t')[1] -replace 'refs/heads/','' }"`) do (
        set /a BRANCH_COUNT+=1
        set "BRANCH_!BRANCH_COUNT!=%%a"
    )

    if !BRANCH_COUNT! gtr 0 (
        echo.
        echo Available branches:
        echo.
        
        set "TARGET_DEFAULT=!DEFAULT_BRANCH!"
        if not "!LAST_SELECTED!"=="" (
            set "TARGET_DEFAULT=!LAST_SELECTED!"
        )

        REM Display branches with numbers
        for /l %%i in (1,1,!BRANCH_COUNT!) do (
            call set "BRANCH=%%BRANCH_%%i%%"
            set "DISPLAY=!BRANCH!"
            set "INDICATORS="
            if "!BRANCH!"=="!DEFAULT_BRANCH!" set "INDICATORS=REMOTE DEFAULT"
            if "!BRANCH!"=="!LAST_SELECTED!" (
                if "!INDICATORS!"=="" (set "INDICATORS=LAST USED") else (set "INDICATORS=!INDICATORS!, LAST USED")
            )
            if not "!INDICATORS!"=="" set "DISPLAY=!DISPLAY! [!INDICATORS!]"
            echo   %%i. !DISPLAY!
        )
        set /a CUSTOM_OPTION=!BRANCH_COUNT!+1
        echo   !CUSTOM_OPTION!. Enter custom branch/tag
        echo.
        
        set "USER_CHOICE="
        set /p "USER_CHOICE=Select option (1-!CUSTOM_OPTION!) or press Enter for [!TARGET_DEFAULT!]: "
        
        if "!USER_CHOICE!"=="" (
            set "SELECTED_BRANCH=!TARGET_DEFAULT!"
            goto :save_branch_selection
        )
        
        REM Check if user entered the custom option number
        if "!USER_CHOICE!"=="!CUSTOM_OPTION!" (
            set /p "SELECTED_BRANCH=Enter branch/tag name: "
            if "!SELECTED_BRANCH!"=="" set "SELECTED_BRANCH=!TARGET_DEFAULT!"
            goto :save_branch_selection
        )
        
        REM Check if it's a valid branch number
        set "FOUND_BRANCH=0"
        for /l %%i in (1,1,!BRANCH_COUNT!) do (
            if "!USER_CHOICE!"=="%%i" (
                call set "SELECTED_BRANCH=%%BRANCH_%%i%%"
                set "FOUND_BRANCH=1"
            )
        )
        
        if "!FOUND_BRANCH!"=="0" (
            REM Treat input as direct branch name
            set "SELECTED_BRANCH=!USER_CHOICE!"
        )
        goto :save_branch_selection
    )

    REM Fallback menu if git ls-remote failed
    echo.
    echo Available options:
    echo.

    set "TARGET_DEFAULT=!DEFAULT_BRANCH!"
    if not "!LAST_SELECTED!"=="" (
        set "TARGET_DEFAULT=!LAST_SELECTED!"
    )

    echo   1. !DEFAULT_BRANCH! [REMOTE DEFAULT]
    set "MAX_CHOICE=1"

    if not "!LAST_SELECTED!"=="" (
        if not "!LAST_SELECTED!"=="!DEFAULT_BRANCH!" (
            echo   2. !LAST_SELECTED! [LAST USED]
            echo   3. Enter custom branch/tag
            set "MAX_CHOICE=3"
        ) else (
            echo   2. Enter custom branch/tag
            set "MAX_CHOICE=2"
        )
    ) else (
        echo   2. Enter custom branch/tag
        set "MAX_CHOICE=2"
    )
    echo.

    set "USER_CHOICE="
    set /p "USER_CHOICE=Select option (1-!MAX_CHOICE!) or press Enter for [!TARGET_DEFAULT!]: "

    if "!USER_CHOICE!"=="" (
        set "SELECTED_BRANCH=!TARGET_DEFAULT!"
    ) else if "!USER_CHOICE!"=="1" (
        set "SELECTED_BRANCH=!DEFAULT_BRANCH!"
    ) else if "!USER_CHOICE!"=="2" (
        if "!MAX_CHOICE!"=="3" (
            set "SELECTED_BRANCH=!LAST_SELECTED!"
        ) else (
            set /p "SELECTED_BRANCH=Enter branch/tag name: "
            if "!SELECTED_BRANCH!"=="" set "SELECTED_BRANCH=!TARGET_DEFAULT!"
        )
    ) else if "!USER_CHOICE!"=="3" (
        if "!MAX_CHOICE!"=="3" (
            set /p "SELECTED_BRANCH=Enter branch/tag name: "
            if "!SELECTED_BRANCH!"=="" set "SELECTED_BRANCH=!TARGET_DEFAULT!"
        ) else (
            set "SELECTED_BRANCH=!USER_CHOICE!"
        )
    ) else (
        set "SELECTED_BRANCH=!USER_CHOICE!"
    )

    goto :save_branch_selection
) else (
    REM Local mode - skip branch selection
    set "SELECTED_BRANCH=local_mode"
    goto :launch_multischolar
)

:save_branch_selection
REM Save selection for next time
echo !SELECTED_BRANCH!>"%PERSISTENCE_FILE%"

:launch_multischolar
echo.
echo Selected branch: !SELECTED_BRANCH!
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

REM Run the R launch script with selected branch as argument
"!RSCRIPT_PATH!" "%LAUNCHER_DIR%launch_multischolar.R" "!SELECTED_BRANCH!" "%LOCAL_FLAG%"
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
