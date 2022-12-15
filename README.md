# SymLink Installer

This script is used to create a symbolic link on a Windows system. It requires administrative privileges to run.

The script first checks the architecture of the operating system, and then looks for a matching entry in a JSON file called `paths.json`. The JSON file should contain a list of objects with the following format:

```json
{
"architecture": "ARCH",
"source": "C:\path\to\source",
"target": "C:\path\to\target"
}
```

where `ARCH` is the architecture of the system (either `32-bit` or `64-bit`).

The script will then check if the source and target paths exist, and if the target path is on an NTFS file system. If all these conditions are met, the script will prompt the user to confirm whether to replace the target if it already exists. If the user confirms, the script will create the symbolic link, overwriting the target if it exists.

The script will exit with an error message if any of the above steps fail.
