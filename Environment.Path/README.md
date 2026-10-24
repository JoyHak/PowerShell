# Environment.Path

Manipulate and retrieve `Path` environment variable.

## Table of Contents

- [Management](#management)
  - [Scope](#scope)
  - [Add-EnvPath](#add-envpath)
  - [Remove-EnvPath](#remove-envpath)
  - [Repair-EnvPath](#repair-envpath)
- [Inspection](#inspection)
  - [Get-EnvPath](#get-envpath)
  - [Find-EnvPath](#find-envpath)
- [Utilities](#utilities)
  - [Resolve-EnvPath](#resolve-envpath)
  - [Set-EnvironmentVariable](#set-environmentvariable)
- [Aliases](#aliases)

<br><br>
Adding a path to this variable allows you to call any file by its name without having to specify the full path:

- Run any script or executable via PowerShell:

```powershell
Start-Process notepad++.exe
&"notepad++.exe"
```

- Save CLI utility to run it from `cmd`, `ps1`, `ahk`, etc. scripts:

```bash
cmd start es.exe image:  # from C:\Program Files\Everything 1.5a
cmd /c powercfg /h off   # from C:\Windows\System32

run("winver")
subprocess.run("pandoc")
```

- Run anything via `Win+R` dialog:

```bash
QuickSwitch.exe
es.exe file:paper.docx
```

- Run apps and load libraries via WinApi (e.g. `LoadLibrary("mylib.dll")`)

This module solves some issues related to managing variable and provides new capabilities.

---

## Management

### Scope

All functions operate on a variable within one of the available scopes:

| Scope          | Description                                                                                                                                 |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| Session        | Affects only the current session. All **added** paths are cleared after pwsh is restarted. The paths are not accessible to other processes. |
| User (default) | Paths available for current user: scripts, apps, launched by current user.                                                                  |
| Machine        | System-wide paths (may require elevation)                                                                                                   |

The current *session* scope is always updated immediately. E.g. the added path becomes available for use immediately.

### Add-EnvPath

*Alias: `addpath`*
Adds a folder to the selected scope. Resolves the provided path, normalizes it, and appends it to the variable if it does not already exist. The current session is updated immediately.

| Parameter       | Required | Type     | Description               |
| --------------- | -------- | -------- | ------------------------- |
| `path`          | Yes      | string[] | The folder path(s) to add |
| [scope](#scope) | No       | string   | Scope to modify           |

> [!NOTE] 
>  The target path does not have to exist on the disk. Non-executable files and variables are preserved (but not expanded). If a file path with executable extension is provided, shows an error — use the directory containing the file instead.

<details>
  <summary>Examples</summary>

```powershell
# Add to current user's PATH
Add-EnvPath C:\Users\ToYu\ripgrep

# Add relative path to current session only
Add-EnvPath -Path .\Microsoft\WindowsApps -Scope Session

# Add to machine-wide PATH (requires elevation)
Add-EnvPath -Path C:\Users\ToYu\Notepad++ -Scope Machine

# Chain with Find-EnvPath to make git available for all users
Find-EnvPath git -Scope User | Add-EnvExe -Scope Machine
```

<img src="../images/addpath.webp" width="450" />

</details>

### Remove-EnvPath

*Alias: `rempath`*
Removes a folder from the selected scope. Resolves the provided path and removes all matching entries. If the path is not present, the function returns nothing without changing the variable.

| Parameter       | Required | Type     | Description                           |
| --------------- | -------- | -------- | ------------------------------------- |
| `path`          | Yes      | string[] | The path(s), folder name(s) to remove |
| [scope](#scope) | No       | string   | Scope to modify                       |

If path is relative, resolves it to the current working directory.
If only a name is provided, removes all matches.

<details>
  <summary>Examples</summary>

```powershell
# Remove a full path
Remove-EnvPath C:\Users\ToYu\ripgrep

# Remove all matching directories by name
Remove-EnvPath ripgrep

# Remove relative path from current session
Remove-EnvPath -Path .\Microsoft\WindowsApps -Scope Session

# Remove all paths to VCS applications
Find-EnvPath git, gitbutler, but | Split-Path -Parent | Remove-EnvPath
```

<img src="../images/rempath.webp" width="400" />

</details>

### Repair-EnvPath

Repairs the PATH value for the selected scope. Normalizes entries by trimming quotes and whitespace, removes empty values, and optionally keeps only entries that exist or are directories.

| Parameter       | Required | Type   | Description                               |
| --------------- | -------- | ------ | ----------------------------------------- |
| [scope](#scope) | No       | string | Scope to repair                           |
| `exists`        | No       | switch | Removes entries that do not exist on disk |
| `folders`       | No       | switch | Remove non-directories                    |

Normally, [Add-EnvPath](#add-envpath) prevents the addition of empty values (`; ;`) or file paths (since they have no effect). However, if the variable contains garbage values, you can clear them to prevent the variable from potentially exceeding its size limit.

<details>
  <summary>Examples</summary>

```powershell
# Basic repair (trim quotes, whitespace, remove empty)
Repair-EnvPath -scope User

# Remove non-existent entries from system PATH
Repair-EnvPath -scope Machine -exists

# Keep only directory entries in current session
Repair-EnvPath -scope Session -folders
```

<img src="../images/Repair-EnvPath.webp" width="350" />

</details>

## Inspection

### Get-EnvPath

*Aliases: `path`, `finddir`, `findfolder`*

Gets matching paths from the variable. Returns any occurrence of the searched directory name or path.

> **Note:** Unlike other functions in this module, the path must exist on disk. Otherwise it returns an empty array.

| Parameter       | Required | Type     | Description                                         |
| --------------- | -------- | -------- | --------------------------------------------------- |
| `path`          | No       | string[] | Full or relative path or name of the file/directory |
| [scope](#scope) | No       | string   | Scope to search in (default: `Session`)             |

If path is relative, resolves it to the current working directory (`Path` contains only absolute paths). 
If parameters are omitted, returns all paths.

<details>
  <summary>Examples</summary>

Search for "notepad" in current session:

```powershell
PS C:\> path notepad
C:\Windows\system32\notepad
C:\Users\ToYu\Notepad++
```

Search for "conemu" user paths:
PS C:\> path conemu -scope User
C:\Users\ToYu\cmder\vendor\conemu-maximus5
C:\Users\ToYu\AppData\Local\ConEmu

```
Full path search can be used to verify that path is present in the variable:
```

PS C:\> path C:\Windows\system32
C:\Windows\system32  # found = added

```
List all entries (current session):
```powershell
PS C:\> Get-EnvPath

C:\Program Files\PowerShell\7
C:\Windows\system32
C:\Windows\System32\Wbem
. . .
```

</details>

<img src="../images/path.webp" width="350" />

### Find-EnvPath

*Alias: `findfile`*

Finds files in paths, found in the variable. Returns any ocurrence of the searched filename in the folders contained in path variable. Gives more flexibility in selecting what we wan't to execute instead of just typing the executables name to the CLI or our script and relying on the Windows firstmatch principle.

| Parameter       | Required | Type     | Description                               |
| --------------- | -------- | -------- | ----------------------------------------- |
| `name`          | Yes      | string[] | Name of the executable file to search for |
| [scope](#scope) | No       | string   | Scope to search in (default: `Session`)   |

For example:

```powershell
PS C:\> Get-EnvPath -filename notepad.exe
C:\Windows\system32\notepad.exe <---- first  match
C:\Windows\notepad.exe          <---- second match
```

> [!NOTE]
> Unlike other functions in this module, the file must exist on disk. Otherwise it returns an empty string.

<details>
  <summary>Examples</summary>

Search in user paths (extension is optional):

```powershell
PS C:\> Find-EnvPath conemu64 -scope User
C:\Users\ToYu\cmder\vendor\conemu-maximus5\conemu64.exe
```

Search multiple executables:

```powershell
PS C:\> Find-EnvPath conemu, git
C:\Users\ToYu\cmder\vendor\conemu-maximus5\conemu64.exe
C:\Program Files\Git\cmd\git.exe
```

Check if a path is present in environment:

```powershell
Find-EnvPath C:\Windows\system32\notepad.exe
Find-EnvPath C:\Users\ToYu\cmder
```

Get help for all matching paths:

```powershell
Find-EnvPath git, gitbutler, but | ForEach { Get-HelpMessage $_ }
```

Remove all paths to VCS applications:

```powershell
Find-EnvPath git, gitbutler, but | Split-Path -Parent | Remove-EnvPath
```

</details>

<img src="../images/findfile.webp" width="350" />
<img src="../images/findfile2.webp" width="350" />

## Utilities

### Resolve-EnvPath

Normalizes a path string for safe use in PATH entries. Trims whitespace, resolves a real filesystem path when possible, and returns a consistent format without a trailing backslash.

| Parameter | Required | Type     | Description              |
| --------- | -------- | -------- | ------------------------ |
| `path`    | Yes      | string[] | The path(s) to normalize |

 If the path does not exist, it is still converted to a full absolute path relative to the current working directory. Variables are preserved (but not expanded).

<details>
  <summary>Examples</summary>

```powershell
# Convert relative path to absolute
Resolve-EnvPath ".\tools\bin"

# Remove trailing backslash
Resolve-EnvPath "C:\Tools\bin\"

# Works even if path does not exist
Resolve-EnvPath "C:\This\Folder\Does\Not\Exist"
```

</details>

### Set-EnvironmentVariable

Sets an environment variable in the selected scope. Writes the variable to either the current session, the current user profile, or the machine-wide environment. If the value is empty, the variable is removed.

| Parameter       | Required | Type   | Description                                                                                |
| --------------- | -------- | ------ | ------------------------------------------------------------------------------------------ |
| `name`          | Yes      | string | Name of the environment variable to set or remove                                          |
| `value`         | No       | object | Value to assign. Use explicit empty string to remove the variable (accepts pipeline input) |
| [scope](#scope) | No       | string | Scope to update in (default: `User`)                                                       |

> [!NOTE]
> The original .NET implementation of `SetEnvironmentVariable` is slow [because it broadcasts a system-wide environment change via `WM_SETTINGCHANGE`](https://github.com/dotnet/dotnet/blob/ee344f85ef890dd92974e9b93d75906f1f8c39f3/src/runtime/src/libraries/System.Private.CoreLib/src/System/Environment.Windows.cs#L455) and waits for ALL PROCESSES to process it. My function avoids that slow broadcast by reducing timeout to 50ms.

> [!CAUTION]
>
> This function will slow down your script! Whenever possible, reduce calls to it.

<details>
  <summary>Examples</summary>

```powershell
# Add to user PATH
Set-EnvironmentVariable Path -Value "C:\Users\ToYu\ripgrep;C:\Users\ToYu\Notepad++" -Scope User

# Set session variable
Set-EnvironmentVariable JAVA_HOME -Value C:\oracle\jdk\bin -Scope Session

# Remove a variable
Set-EnvironmentVariable MY_VAR -Value "" -Scope User
```

</details>

## Aliases

| Alias        | Function         | Description                      |
| ------------ | ---------------- | -------------------------------- |
| `path`       | `Get-EnvPath`    | Search PATH for directories      |
| `finddir`    | `Get-EnvPath`    | Alias for Get-EnvPath            |
| `findfolder` | `Get-EnvPath`    | Alias for Get-EnvPath            |
| `findfile`   | `Find-EnvPath`   | Search PATH for executable files |
| `addpath`    | `Add-EnvPath`    | Add a folder to PATH             |
| `rempath`    | `Remove-EnvPath` | Remove a folder from PATH        |

---

## License

[GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.html)
