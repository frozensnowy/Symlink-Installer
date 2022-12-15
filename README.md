# SymLink Installer

This script is a Windows Batch file that creates a symbolic link (symlink) on a local machine. A symlink is a type of file that points to another file or directory on the file system. This script allows the user to specify the source and target paths for the symlink in a JSON files named `files.json`, `registry.json` and `shortcuts.json` respectively.

The script first checks for administrative privileges by using the runas command, which will prompt the user to enter their credentials if they are not an administrator. It then determines the architecture of the operating system (32-bit or 64-bit) using the wmic command, and checks if the required JSON files exist.

Next, the script reads files.json and uses the findstr command to locate the block of JSON that contains the source and target paths for the specified operating system architecture. If no matching architecture is found, the script exits with an error.

The script then checks if the source and target paths exist, and creates the necessary directory structures if they do not. It also checks if the target path is on an NTFS file system (necessary for creating symlinks), and prompts the user to replace the target if it already exists. Finally, the script creates the symlink using the mklink command, which allows the user to access the files in the source directory through the target directory.

The script also uses the registry.json and shortcuts.json files to add registry values and create shortcuts on the local machine. For the registry.json file, the script reads each key object in the JSON and checks if it is for the current operating system architecture. If the registry value already exists, the script modifies it, otherwise it adds the registry value.

For the shortcuts.json file, the script reads each shortcut object in the JSON and creates a symbolic link or shortcut, depending on the version of Windows. For Windows versions older than Vista, it creates a symbolic link using the `mklink` command. For Windows Vista or later, it creates a shortcut using the `mklink` command with the `/H` option.


## Usage

1. Clone the repository to your local machine.
2. Make sure the JSON configuration files (`files.json`, `registry.json`, and `shortcuts.json`) are in the same directory as the script.
3. Double-click the `symlink-installer.bat` file to run the script.

## JSON Configuration Files

The script requires the following JSON configuration files:

### files.json

The `files.json` file contains the source and target paths for the symbolic links. The file should be formatted as follows:

```json
{
  "files": [
    {
      "architecture": "32-bit",
      "source": "c:\\path\\to\\source1",
      "target": "c:\\path\\to\\target1"
    },
    {
      "architecture": "64-bit",
      "source": "c:\\path\\to\\source2",
      "target": "c:\\path\\to\\target2"
    }
  ]
}
```

registry.json (optional)

The registry.json file contains the registry keys that need to be updated with the target path. The file should be formatted as follows:

```json
{
  "registry": [
    {
      "architecture": "32-bit",
      "path": "HKEY_LOCAL_MACHINE\\Software\\MyApp\\Settings",
      "value": "C:\\Program Files\\MyApp"
    },
    {
      "architecture": "64-bit",
      "path": "HKEY_LOCAL_MACHINE\\Software\\MyApp\\Settings",
      "value": "C:\\Program Files\\MyApp"
    }
  ]
}
```

shortcuts.json (optional)

The shortcuts.json file contains the shortcuts that need to be created and updated with the target path. The file should be formatted as follows:

```json
{
  "shortcuts": [
    {
      "source": "C:\\Program Files\\My App\\MyApp.exe",
      "destination": "C:\\Desktop\\MyAppShortcut.lnk",
      "arguments": "-someargument"
    },
    {
      "source": "C:\\Program Files\\My App\\MyApp2.exe",
      "destination": "C:\\Desktop\\MyAppShortcut2.lnk",
      "arguments": "-someotherargument"
    }
  ]
}
```

### Notes

- The script requires administrator privileges to run. If you do not have administrator privileges, the script will prompt you to enter your credentials and will relaunch itself with the necessary privileges.
- The `registry.json` and `shortcuts.json` files are optional. If they are not found, the script will display a warning but will continue to run.
- The script includes error handling to check if the source and target paths exist, if the necessary directories have been created, and if the target path is on an NTFS file system.
- The script will prompt the user to replace the target path if it already exists.
- There is also an `uninstall.cmd` script that can be used to undo the changes of the install scrip.

### Credits

This script was inspired by a script I created previously for making portable versions of software for use in collaboration with @mczaplinski. Check his github out here: https://github.com/mczaplinski
