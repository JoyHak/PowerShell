# SystemEssentials

Designed to simplify essential tasks.

---

## Table of Contents

- [Help & Documentation](#help--documentation)
  - [Get-HelpMessage](#get-helpmessage)
  - [Get-HelpSyntax](#get-helpsyntax)
  - [Get-HelpExample](#get-helpexample)
- [Script Management](#script-management)
  - [Stop-Script](#stop-script)
  - [Stop-HiddenScript](#stop-hiddenscript)
- [Logging & Output](#logging--output)
  - [Write-Log](#write-log)
  - [Write-Detail](#write-detail)
  - [Out-VerboseTee](#out-verbosetee)
- [Paging](#paging)
  - [Out-More](#out-more)
- [Utilities](#utilities)
  - [ConvertTo-EscapedArguments](#convertto-escapedarguments)
  - [Get-Error](#get-error)
  - [Get-LineCount](#get-linecount)
- [System Information](#system-information)
  - [Get-WindowsVersion](#get-windowsversion)
  - [Get-WindowsVersionString](#get-windowsversionstring)
  - [Get-PowershellVersionString](#get-powershellversionstring)
  - [Get-AliasTable](#get-aliastable)
- [Aliases](#aliases)

<br>[Help & Documentation](#help--documentation) functions allow you to learn PowerShell and CLI utilities:

- Retrieve all avaialble functions:

```powershell
Get-Command -Module SystemEssentials -CommandType Function, Alias
```

- Get detailed documentation for each function:

```powershell
hlp Stop-Script -full
hlp Stop-Script -detailed
```

- Get signature (parameters):

```powershell
usage Stop-Script
usage Remove-Checkpoint
```

<details>
  <summary>Example output</summary>

```powershell
Stop-Script
   [-names] <string[]>
   [[-launcher] <string>]
   [-force]
   [-confirm]
   [<CommonParameters>]

Remove-Checkpoint
   [[-SequenceNumber] <Object>]
   [-WhatIf]
   [-Confirm]
   [<CommonParameters>]
```

</details>

<br><br>[Script Management](#script-management) is designed to stop hanging or hidden scripts (like Python, Autohotkey, anything you have).  To manage you scripts (launch, stop, auto-startup, etc.) see [Launcher](https://github.com/JoyHak/Launcher) utility.

<br><br>Other functions make it easier to perform essential tasks and write scripts.

---

## Help & Documentation

### Get-HelpMessage

*Aliases: `hlp`, `h`*

Retrieves help information for PowerShell commands or external applications.

| Parameter   | Required | Type     | Description                                                             |
| ----------- | -------- | -------- | ----------------------------------------------------------------------- |
| `command`   | Yes      | string   | PowerShell command name, alias, or path to an executable                |
| `arguments` | No       | string[] | Arguments to pass to the command (for Get-Help or external subcommands) |

<details>
  <summary>Examples</summary>

Retrieve help for the PowerShell functions:

```powershell
hlp Get-Process
hlp Stop-HiddenScript
```

 Retrieve help for specific parameters or full help message (see [Get-Help](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/get-help?view=powershell-7.6#examples) for all available parameters):

```powershell
hlp Stop-HiddenScript -Parameter launcher
hlp Stop-HiddenScript -full
```

Retrieve help for apps:

```powershell
hlp pip
hlp git
```

Retrieve help for the sub-commands:

```powershell
hlp pip install
hlp but diff
hlp git diff
hlp gh repo clone
```

Absolute and realtive paths are supported:

```powershell
hlp "C:\Program Files\Git\cmd\git.exe"
hlp .\notepad++.exe
```

</details>

> [!TIP]
> You can set more convenient alias in your profile (`notepad $profile`):
>
> ```powershell
> Remove-Alias ? -Force
> Set-Alias ? Get-HelpMessage
> ```
>
> Usage example:
>
> ```powershell
> ? Get-Process
> ? gh repo clone
> ```
>
> <img src="../images/Get-HelpMessage.avif" width="450" />

### Get-HelpSyntax

*Aliases: `?!`, `syntax`, `usage`*

Extracts and formats syntax for PowerShell commands and external applications.

| Parameter   | Required | Type     | Description                                           |
| ----------- | -------- | -------- | ----------------------------------------------------- |
| `command`   | Yes      | string   | Command name, alias, or path to an executable         |
| `arguments` | No       | string[] | Additional arguments to retrieve raw help with syntax |

#### Parameter notation

PowerShell and many applications are using the following notaion in the help messages:

| Syntax            | Meaning                                             |
| ----------------- | --------------------------------------------------- |
| `[[-name] <val>]` | optional parameter, can be used by position or name |
| `[-name <val>]`   | optional parameter, can only be used by name        |
| `[-name] <val>`   | required parameter, can be used by position or name |
| `-name <val>`     | required parameter, can only be used by name        |
| `[-name]`         | switch parameter (always optional, only by name)    |

<details>
  <summary>Examples</summary>

Retrieve usage of the PowerShell functions:

```powershell
usage Get-Process
usage Stop-HiddenScript
```

Retrieve usage of apps:

```
usage pip
usage git
```

Retrieve usage of the sub-commands:

```
usage pip install
usage but diff
```

Absolute and realtive paths are supported:

```powershell
usage "C:\Program Files\Git\cmd\git.exe"
usage .\notepad++.exe
```

</details>

### Get-HelpExample

Extracts and formats usage examples for PowerShell commands and external applications.

| Parameter   | Required | Type     | Description                                             |
| ----------- | -------- | -------- | ------------------------------------------------------- |
| `command`   | Yes      | string   | Command name, alias, or path to an executable           |
| `arguments` | No       | string[] | Additional arguments to retrieve raw help with examples |

<details>
  <summary>Example output</summary>

```powershell
# All examples for Get-Command
Get-HelpExample Get-Command
Get-HelpExample hlp

# Examples for ls alias
Get-HelpExample ls

# GitHub CLI examples
Get-HelpExample gh search
```

</details>

## Script Management

### Stop-Script

*Aliases: `kills`, `stop`*

Stops running scripts by name, searching for processes that have the file in their command line. Tries multiple methods sequentially.

| Parameter  | Required | Type     | Description                                                       |
| ---------- | -------- | -------- | ----------------------------------------------------------------- |
| `names`    | Yes      | string[] | Script names to stop (accepts pipeline input)                     |
| `launcher` | Yes      | string   | Handler process name (default: `autohotkey`). **Cannot be empty** |
| `force`    | No       | switch   | Stop without confirmation prompt                                  |
| `confirm`  | No       | switch   | Prompt for confirmation before stopping each script               |

Outputs a formatted table of terminated processes showing `Id` and `ProcessName`, along with status messages indicating success or failure.

<details>
  <summary>Example output</summary>

```powershell
# Stop multiple AutoHotkey scripts
Stop-Script "Script1", "Script2"

# With confirmation
Stop-Script "Script1", "Script2" -confirm

# Stop Python scripts
kills -names "Script1.py", "Script2.py" -launcher "python" -force
```

<img src="../images/Stop-Script.webp" width="850" />

</details>

### Stop-HiddenScript

Stops hidden running scripts by path or name. Searches for hidden windows with the specified path in the title.

| Parameter  | Required | Type     | Description                                                                         |
| ---------- | -------- | -------- | ----------------------------------------------------------------------------------- |
| `names`    | Yes      | string[] | Paths/names of scripts to stop (accepts pipeline input)                             |
| `launcher` | No       | string   | Handler process name (e.g., `autohotkey`, `python`). Filters by `launcher*` pattern |
| `force`    | No       | switch   | Stop without confirmation prompt                                                    |
| `confirm`  | No       | switch   | Prompt for confirmation before stopping each script                                 |

This is more powerful alternative to [Stop-Script](#stop-script), but it requires [Everything search tool](https://www.voidtools.com/support/everything/) to instantly find the paths to the scripts on your drive and terminate them.

You can specify full or relative paths to the scripts or just filenames to find all matches.

> [!NOTE]
>
> Requires and [es.exe](https://www.voidtools.com/support/everything/command_line_interface/) to be in Path variable. After installation launch `Everything.exe` and wait until creates full disk index. It's requried for the fast-kill.
>
> You can add it to the Path by Add-EnvPath (doesn't requires restart).

<details>
  <summary>Example output</summary>

Stop multiple scripts:

```powershell
Stop-HiddenScript "C:\Script1.ahk", "C:\Script2.py"
```

With confirmation (search by name):

```powershell
Stop-Script "Script1.ahk", "Script2.py" -confirm
```

With handler filter:

```powershell
Stop-HiddenScript -names "Script1.py", "Script2.py" -launcher "python" -force
```

<img src="../images/Stop-HiddenScript.avif" width="450" />

</details>

## Logging & Output

### Write-Log

Outputs a message to the console and writes it to a log file. Automatically creates a file with the current date on the first call. To fully control the output use [Write-Detail](#write-detail) and [Out-VerboseTee](#out-verbosetee).

| Parameter     | Required | Type   | Description                                                     |
| ------------- | -------- | ------ | --------------------------------------------------------------- |
| `Message`     | Yes      | string | Message text (accepts pipeline input)                           |
| `Level`       | No       | string | Level: `Info` (default), `Debug`, `Verbose`, `Warning`, `Error` |
| `LogFullPath` | No       | string | Full path to the log file. If omitted, auto-generated           |

This command is designed for simple messages logging. It doesn't requires multiple parameters per each call, only the message.

If a path to a file to write to was not specified, it will be created automatically with the current date in . format and all subsequent calls to Write-Log will write messages to this file.

#### Levels and colors

| Level   | Color    | Display Condition                               |
| ------- | -------- | ----------------------------------------------- |
| Info    | White    | Always                                          |
| Verbose | Cyan     | `$VerbosePreference -ne 'SilentlyContinue'`     |
| Debug   | DarkGray | `$DebugPreference -ne 'SilentlyContinue'`       |
| Warning | Yellow   | `$WarningPreference -ne 'SilentlyContinue'`     |
| Error   | Red      | `$ErrorActionPreference -ne 'SilentlyContinue'` |

<details>
  <summary>Examples</summary>

```powershell
# Basic call
Write-Log 'Tracing script'
12:13:00 [INFO]  Tracing script

# With level and file
Write-Log 'Tracing script' 'Debug' 'trace.log'
12:21:41 [DEBUG]  Tracing script

# Dumps information about current system 
# to the generated log.

Get-WindowsVersion | ConvertTo-Json | Write-Log

# Switching log file
Write-Log 'First message' 'Info' 'info.log'
Write-Log 'Second message' 'Info'          # writes to info.log
Write-Log 'Warning!' 'Warning' 'warns.log' # switches to warns.log
```

You can override the file for all subsequent calls:

```powershell
Write-Log 'Tracing script' 'Info' 'info.log'
Write-Log 'Init variables' 'Info'  <-- writes to info.log
Write-Log 'Create objects' 'Info'  <-- writes to info.log
Write-Log 'Wrong files' 'Warning' 'warns.log'
Write-Log 'Locked file' 'Warning'  <-- writes to warns.log
```

</details>

> [!TIP]
> Install [Maple Mono font](https://github.com/subframe7536/maple-font) to see pretty prefix.
> <img src="../images/Write-Log.avif" width="450" />  

### Write-Detail

Writes a detailed message with a timestamp and prefix. Designed for use inside [advanced functions](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced?view=powershell-7.6).

| Parameter | Required | Type   | Description                                            |
| --------- | -------- | ------ | ------------------------------------------------------ |
| `Message` | Yes      | string | The message text                                       |
| `Prefix`  | No       | string | Block prefix: `BEGIN`, `PROCESS` (default), `END`      |
| `Date`    | No       | switch | Display full date (e.g., `9/15/2024 11:36:41`)         |
| `Time`    | No       | switch | Display time with milliseconds (e.g., `11:37:01:4029`) |

This command is designed to be used within your functions and scripts to make it easier to write a detailed message that you can as verbose output. The assumption is that you are using an advanced function with `Begin`, `Process`, and `End` scriptblocks. You can create a detailed message to indicate what part of the code is being executed. The output can include a full-time stamp, or a time string which includes a millisecond value.  

<details>
  <summary>Examples</summary>

Normally you would use this command in a function, but here is an examples from the console so that you can see what to expect:

```powershell
PS C:\> Write-Detail -message "Initializing variables" -Prefix Begin -time
01:25:29:8700 [BEGIN] Initializing variables

PS C:\> Write-Detail "Getting file information" -Prefix Process
[PROCESS] Getting file information
```

And more common usage:

```powershell
# Standard format
Write-Detail "Getting file information" -Prefix Process

# With time and milliseconds
Write-Detail -Message "Initializing variables" -Prefix Begin -Time

# With full date
Write-Detail -Message "Starting" -Date
```

</details>

### Out-VerboseTee

*Alias: `log`, `stdout`*

Writes a message to the verbose stream and to a file. Only works when `$VerbosePreference = "continue"`.

| Parameter  | Required | Type     | Description                                |
| ---------- | -------- | -------- | ------------------------------------------ |
| `Value`    | Yes      | object   | Message to output (accepts pipeline input) |
| `Path`     | Yes      | string   | Output file path                           |
| `Encoding` | No       | Encoding | File encoding                              |
| `Append`   | No       | switch   | Append to file instead of overwriting      |

This command is intended to let you see your verbose output and write the verbose messages to a log file. It will only work if the verbose pipeline is enabled, usually when your command is run with `-Verbose`. It is designed to be used within your scripts and functions.

When the command is run with `-Verbose` you will see the verbose output and it will be saved to the specified log file.

<details>
  <summary>Examples</summary>

```powershell
$VerbosePreference = "continue"
Write-Detail "This is a verbose log test" | Out-VerboseTee -Path .\verbose.log
```

Normally you would use this command inside a function or script, but you can run it from the console if you want to understand how it works:

```powershell
PS C:\> Write-Detail "This is a verbose log test" | Out-VerboseTee -Path $log
PS C:\> Get-Content $log
11/29/2024 08:21:31:0704 [PROCESS] This is a verbose log test  
```

</details>

## Paging

### Out-More

*Alias: `more`, `detailed`*

Pages output of objects in the pipeline. Default: 50 objects per page.

| Parameter     | Required | Type     | Description                                 |
| ------------- | -------- | -------- | ------------------------------------------- |
| `InputObject` | Yes      | object[] | Objects to display (accepts pipeline input) |
| `Count`       | No       | int      | Objects per page (1–1000, default: **50**)  |
| `ClearScreen` | No       | switch   | Clear the screen before output              |

This function is designed to display groups or "pages" of objects to the PowerShell pipeline. It is modeled the legacy `more` command-line utility. By default, the it will write objects out to the pipeline in groups of 50. You will be prompted after each grouping.

#### Navigation keys during pause

| Key           | Action                     |
| ------------- | -------------------------- |
| `M` / `Enter` | Show next page             |
| `A`           | Show all remaining objects |
| `N`           | Show next single object    |
| `Q`           | Stop output                |

<details>
  <summary>Examples</summary>

List all files in C:\Work and page them to Out-More using the default count, but after clearing the screen first. The results are then piped to `Tee-Object` which saves them to a variable:

```bash
PS C:\> dir c:\work -file -Recurse | more -ClearScreen | log -Variable work
```

Display processes in groups of 10:

```powershell
    PS C:\> Get-Process | Out-More -count 10
    Handles  NPM(K)    PM(K)      WS(K) VM(M)   CPU(s)     Id  SI ProcessName
    -------  ------    -----      ----- -----   ------     --  -- -----------
        103       9     1448       4220    67     0.02   1632   0 BtwRSupportService
         80       9     3008       8588 ...27    21.00   5192   1 conhost
         40       5      752       2780 ...82     0.00   5248   0 conhost
         53       7      972       3808 ...07     0.02   6876   1 conhost
        482      17     1932       3692    56     0.91    708   0 csrss
        520      30     2488     134628   180    31.67    784   1 csrss
        408      18     6496      12436 ...35     0.56   1684   0 dasHost
        180      14     3348       6748    66     0.50   4688   0 devmonsrv
    [M]ore [A]ll [N]ext [Q]uit
```

</details>

## Utilities

### ConvertTo-EscapedArguments

Converts an array of argument strings into a properly escaped string for passing to native commands.

| Parameter  | Required | Type     | Description                                       |
| ---------- | -------- | -------- | ------------------------------------------------- |
| `Argument` | Yes      | string[] | Array of argument values (accepts pipeline input) |

<details>
  <summary>Examples</summary>

```powershell
PS C:\> ConvertTo-EscapedArguments "file with spaces.txt", "--option=value"
"file with spaces.txt" "--option=value"
  
PS C:\> ConvertTo-EscapedArguments '"file\with spaces.txt"'
"\"file\with spaces.txt\""  
```

</details>

### Get-Error

Retrieves error descriptions by code via `certutil` or `slui`.

| Parameter | Required | Type   | Description                                      |
| --------- | -------- | ------ | ------------------------------------------------ |
| `code`    | Yes      | string | Error code (e.g., `0xc0000602`, pipeline-able)   |
| `UI`      | No       | switch | Show a Windows dialog with the error description |

<details>
  <summary>Example output</summary>

```powershell
PS C:\> Get-Error 0x80070005
0x80070005 (WIN32: 5 ERROR_ACCESS_DENIED) -- 2147942405 (-2147024891)
Error message text: Access is denied.  
```

```powershell
PS C:\> Get-Error 0xc0000602
0x80070005 (WIN32: 5 ERROR_ACCESS_DENIED) -- 3221227010 (-1073740286)
Error message text: {Exception Fail Fast}
Exception handlers will not be invoked, the process will be terminated immediately.
```

Windows dialog (User Interface), press the "Details" button to see the description:

```powershell
Get-Error -code 0xc0000602 -UI
Get-Error 0x80070005 -UI
```

</details>

### Get-LineCount

*Alias: `lines`*

Recursively counts total lines across files matching a filter.

| Parameter | Required | Type   | Description                            |
| --------- | -------- | ------ | -------------------------------------- |
| `Path`    | No       | string | Root path to search (default: `.`)     |
| `Filter`  | No       | string | File filter pattern (default: `*.ahk`) |

<details>
  <summary>Examples</summary>

Count lines in current directory (`*.ahk` by default):

```powershell
Get-LineCount
```

Specify path and filter

```powershell
Get-LineCount -Path "C:\Scripts" -Filter "*.ps1"
```

Get lines in the specific file:

```powershell
Get-LineCount ".\QuickSwitch\QuickSwitch.ahk"
```

</details>

## System Information

### Get-WindowsVersion

*Alias: `winver`*

Returns detailed information about the current Windows version as an object:

| Property       | Type     | Description                          |
| -------------- | -------- | ------------------------------------ |
| ProductName    | string   | Product name                         |
| DisplayVersion | string   | Display version                      |
| EditionID      | string   | Edition ID                           |
| ReleaseID      | string   | Release ID                           |
| Build          | string   | Build number (Major.Minor.Build.UBR) |
| BuildBranch    | string   | Build branch                         |
| InstalledUTC   | DateTime | Installation date (UTC)              |
| Computername   | string   | Computer name                        |

<img src="../images/winver.webp" width="850" />

### Get-WindowsVersionString

*Alias: `about`*

Formats Windows information into a string like `COMPUTERNAME Windows 11 Pro Version 23H2 (OS Build 22631.4460)`.

### Get-PowershellVersionString

*Alias: `psver`*

Returns the PowerShell version as a string like `7.5.0`.

### Get-AliasTable

*Alias: `aliases`*

Displays a table of all aliases with their definitions and sources:

| Property | Type   | Description                |
| -------- | ------ | -------------------------- |
| Alias    | string | Alias name                 |
| Function | string | Target function or command |
| Source   | string | Source module (if any)     |

<details>
  <summary>Example output</summary>

```powershell
Get-AliasTable

Alias       Function                              Source
-----       --------                              ------                     
?!          Get-HelpSyntax                        SystemEssentials
%           ForEach-Object                        
about       Get-WindowsVersionString              SystemEssentials
ac          Add-Content                           
addpath     Add-EnvPath                           Environment.Path
aliases     Get-AliasTable                        SystemEssentials
cat         Get-Content                           
cd          Set-Location                          
chdir       Set-Location                          
checkpoint  Checkpoint-Computer                   SystemEssentials
checkpoints Get-Checkpoint                        SystemEssentials
```

</details>

## Aliases

| Alias                   | Function                      | Description                        |
| ----------------------- | ----------------------------- | ---------------------------------- |
| `hlp`, `h`              | `Get-HelpMessage`             | Help for commands and applications |
| `?!`, `syntax`, `usage` | `Get-HelpSyntax`              | Command syntax extraction          |
| `kills`, `stop`         | `Stop-Script`                 | Stop scripts by name               |
| `more`, `detailed`      | `Out-More`                    | Paginated output                   |
| `log`                   | `Out-VerboseTee`              | Verbose to console and file        |
| `lines`                 | `Get-LineCount`               | Count lines in files               |
| `escape`                | `ConvertTo-EscapedArguments`  | Argument escaping                  |
| `winver`                | `Get-WindowsVersion`          | Windows version information        |
| `about`                 | `Get-WindowsVersionString`    | Windows version and computer name  |
| `psver`                 | `Get-PowershellVersionString` | PowerShell version                 |
| `aliases`               | `Get-AliasTable`              | Table of all aliases               |

---

## License

[GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.html)
