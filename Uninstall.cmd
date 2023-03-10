:: Warning: You are not allowed to remove this message if you decide to use or redistribute the script
:: This script was created by Frozen Snow. The source code can be found here: https://github.com/frozensnowy/Symlink-Installer
:: It was last edited on 12/15/2022

@Echo off
Echo ############################################################
Echo ##                                                        ##
Echo ##              Symlink UnInstaller Script                ##
Echo ##                                                        ##
Echo ## This script removes symlinks on the local machine. A   ##
Echo ## symlink is a type of file that points to another file  ##
Echo ## or directory on the file system. The user can specify  ##
Echo ## the source and target paths for the symlinks in a JSON ##
Echo ## file named 'files.json'. It only removes the target.   ##
Echo ## The script also adds registry values and creates       ##
Echo ## shortcuts if the 'registry.json' and 'shortcuts.json'  ##
Echo ## files are present.                                     ##
Echo ##                                                        ##
Echo ############################################################
:: Enable delayed expansion to use variables in the for loops
setlocal enabledelayedexpansion




net use \\localhost /savecred >nul 2>&1
if %errorlevel% == 2 (
  echo This script requires administrative privileges.
  echo Please enter your credentials to continue.
  runas /user:administrator "cmd /c %~dp0%0"
  exit
)


:: Check if OS is 32-bit or 64-bit
for /f "skip=1 delims=" %%a in (`wmic os get osarchitecture`) do set OS=%%a
if %ERRORLEVEL% NEQ 0 (
  echo ERROR: Failed to determine OS architecture.
  exit /b
)
echo OS is %OS%

:: Check if files.json exists and is a file
if not exist files.json (
    echo ERROR: files.json not found or is not a file.
    exit /b
)

:: Read the JSON file containing the paths
for /f "usebackq delims=" %%a in (type files.json) do set "JSON=%%a"

:: Iterate over each entry in the paths array
for /f "tokens=2 delims={}" %%a in ('echo %JSON% ^| findstr /b /c:"{" /e /c:"}"') do (
    set "BLOCK=%%a"
    set "BLOCK=!BLOCK:1!"
    for /f "tokens=1,2 delims=:" %%b in ("!BLOCK!") do (
        if "%%b"=="source" (
            set "SOURCE=%%c"
        ) else if "%%b"=="target" (
            set "TARGET=%%c"
        )
    )

    :: Check if the target path exists
    if not exist %TARGET% (
        echo ERROR: Target path %TARGET% does not exist.
        exit /b
    )

    :: Remove the symbolic link
    rmdir %TARGET%
    if %ERRORLEVEL% NEQ 0 (
        echo ERROR: Failed to remove symbolic link.
        exit /b
    )

    :: Check if the target path is now empty
    if exist %TARGET% (
        echo ERROR: Target path %TARGET% is not empty.
        exit /b
    )

    echo Removed symbolic link at %TARGET%
)


:: Read and parse the JSON file containing the registry keys
for /f "usebackq tokens=2 delims={}" %%i in (`type registry.json`) do (
    :: Parse the current key object to get the architecture, path, and value
    for /f "usebackq tokens=*" %%j in (`echo %%i`) do (
        set architecture=%%~j
        set path=%%~k
        set value=%%~l
        set registryType=%%~m
        :: Set default registry type if not specified
        if not defined registryType set registryType=REG_SZ
        :: Add reg_ prefix to registry type if not present
        if not "%registryType:~0,4%" == "reg_" set registryType=reg_%registryType%
        :: Check if the key is for the current OS architecture
        if "!architecture!"=="%OS: =%" (
            :: Delete the registry value
            reg delete %path% /v %value% /f
        )
    )
)


:: Handle any errors that may occur while removing the registry keys
if %ERRORLEVEL% neq 0 (
    echo An error occurred while removing the registry keys.
    pause
    exit /B
)



:: Read and parse the JSON file containing the shortcut information
for /f "delims=" %%i in (shortcuts.json) do (
    :: Parse the current shortcut object to get the destination
    for /f "tokens=1,3 delims=:" %%j in ("%%i") do (
        set destination=%%j
        :: Delete the shortcut or symbolic link at the destination
				del %destination%
				if %ERRORLEVEL% NEQ 0 (
  				echo ERROR: Failed to delete shortcut or symbolic link.
  			)
    )
)

:: Handle any errors that may occur while deleting the links or shortcuts
if %ERRORLEVEL% neq 0 (
    echo An error occurred while deleting the links or shortcuts.
    pause
    exit /B
)

endlocal
:: End
echo Uninstall complete.
pause
