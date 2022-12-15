:: Warning: You are not allowed to remove this message if you decide to use or redistribute the script
:: This script was created by Frozen Snow. The source code can be found here: https://github.com/frozensnowy/Symlink-Installer
:: It was last edited on 12/15/2022

@Echo off
Echo ############################################################
Echo ##                                                        ##
Echo ##               Symlink Installer Script                 ##
Echo ##                                                        ##
Echo ## This script creates symlinks on the local machine. A   ##
Echo ## symlink is a type of file that points to another file  ##
Echo ## or directory on the file system. The user can specify  ##
Echo ## the source and target paths for the symlinks in a JSON ##
Echo ## file named 'paths.json'. The script also adds registry ##
Echo ## values and creates shortcuts if the 'keys.json' and    ##
Echo ## 'shortcuts.json' files are present.                    ##
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
:: Here we use the for /f command's skip option to ignore the first line of the wmic command's output, which contains the column headers. This will make the script more efficient because it will not process the column headers as part of the wmic command's output. 
for /f "skip=1 delims=" %%a in (`wmic os get osarchitecture`) do set OS=%%a
if %ERRORLEVEL% NEQ 0 (
  echo ERROR: Failed to determine OS architecture.
  exit /b
)
echo OS is %OS%

:: Check if paths.json exists and is a file
if not exist paths.json (
    echo ERROR: paths.json not found or is not a file.
    exit /b
)



:: Read the JSON file containing the paths
for /f "usebackq delims=" %%a in (type paths.json) do set "JSON=%%a"

:: Check if any paths were found for the system architecture
for /f "tokens=2 delims={}" %%a in ('echo %JSON% ^| findstr /c:"{" /e /c:"}"') do (
    set "BLOCK=%%a"
    if "!BLOCK:~0,10!"=='"architecture": "%OS%",' (
        set "BLOCK=!BLOCK:1!"
        for /f "tokens=1,2 delims=:" %%b in ("!BLOCK!") do (
            if "%%b"=="source" (
                set "SOURCE=%%c"
            ) else if "%%b"=="target" (
                set "TARGET=%%c"
            )
        )
    )
)
if not defined SOURCE (
    echo ERROR: No matching architecture found in paths.json
    exit /b
)

echo Found architecture: %OS%
echo Source: %SOURCE%
echo Target: %TARGET%

:: Check if the target and source paths already exist
if not exist %SOURCE% (
    echo ERROR: Source path %SOURCE% does not exist.
    exit /b
)
if exist %TARGET% (
    echo ERROR: Target path %TARGET% already exists.
    exit /b
)

:: Create the directory structure for the source and target
mkdir /p %SOURCE%
mkdir /p %TARGET%

:: Check if the target path is on an NTFS file system
for /f "tokens=1" %%a in ('fsutil fsinfo drivetype %TARGET:~0,1%') do (
  if "%%a"=="NTFS" (
    :: Check if the source path is on an NTFS file system
    for /f "tokens=1" %%b in ('fsutil fsinfo drivetype %SOURCE:~0,1%') do (
      if "%%b"=="NTFS" (
        :: Check if the target path exists
        if exist %TARGET% (
          :: Prompt the user to replace the target
          set /p "replace=Replace existing target? [Y/N] "
          if "%replace%"=="Y" (
            :: Create the symbolic link, overwriting the target if it exists
            mklink /d /j %SOURCE% %TARGET%
            if %ERRORLEVEL% NEQ 0 (
              echo ERROR: Failed to create symbolic link.
              exit /b
            )
          )
        ) else (
          :: Create the symbolic link
          mklink /d /j %SOURCE% %TARGET%
          if %ERRORLEVEL% NEQ 0 (
            echo ERROR: Failed to create symbolic link.
            exit /b
          )
        )
      )
    )
  )
)

:: Now we add registry keys to the system using keys.json

:: Read and parse the JSON file containing the registry keys
for /f "usebackq tokens=2 delims={}" %%i in (`type keys.json`) do (
    :: Parse the current key object to get the architecture, path, and value
    for /f "usebackq tokens=*" %%j in (`echo %%i`) do (
        set architecture=%%~j
        set path=%%~k
        set value=%%~l
        :: Check if the key is for the current OS architecture
        if "!architecture!"=="%OS: =%" (
            :: Check if the registry value already exists
            reg query %windir%\system32\%path:~1,1%^"%~dp0%path:~2%^" /v %value:~1,1%^"%~dp0%value:~2%^" /ve | find /i "ERROR"
            if not errorlevel 1 (
                :: Get the type and value of the registry value
                for /f "tokens=2,4 delims==" %%k in (`reg query %windir%\system32\%path:~1,1%^"%~dp0%path:~2%^" /v %value:~1,1%^"%~dp0%value:~2%^" /t ^| find /i "REG_SZ"`) do (
                    set type=%%k
                    set val=%%l
                )
                :: Modify the registry value
                reg add %windir%\system32\%path:~1,1%^"%~dp0%path:~2%^" /v %value:~1,1%^"%~dp0%value:~2%^" /t %type% /d %val% /f
            ) else (
                :: Add the registry value
                reg add %windir%\system32\%path:~1,1%^"%~dp0%path:~2%^" /v %value:~1,1%^"%~dp0%value:~2%^" /t REG_SZ /d %value:~1,1%^"%~dp0%value:~2%^"
            )
        )
    )
)

:: Handle any errors that may occur while adding or modifying the registry keys
if %ERRORLEVEL% neq 0 (
    echo An error occurred while adding or modifying the registry keys.
    pause
    exit /B
)

:: Now we create shortcuts with optional arguments using shortcuts.json

:: Read and parse the JSON file containing the shortcut information
for /f "delims=" %%i in (shortcuts.json) do (
    :: Parse the current shortcut object to get the source, destination, and arguments
    for /f "tokens=1,3,5 delims=:" %%j in ("%%i") do (
        set source=%%j
        set destination=%%k
        set arguments=%%l

        :: Create the appropriate shortcut based on the version of Windows
        if "%SystemRoot%\system32\cmd.exe /c ver | find "6.0" > nul" == "0" (
            :: Windows is Vista or later, create a shortcut
            %windir%\system32\mklink /H %destination% %source% %arguments%
        ) else (
            :: Windows is older than Vista, create a symbolic link
            %windir%\system32\mklink /D %destination% %source% %arguments%
        )
    )
)

:: Handle any errors that may occur while creating the links or shortcuts
if %ERRORLEVEL% neq 0 (
    echo An error occurred while creating the links or shortcuts.
    pause
    exit /B
)

endlocal
echo Install complete.
:: End
pause
