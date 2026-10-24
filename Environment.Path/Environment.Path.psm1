<#
.SYNOPSIS
    Normalizes a path string for safe use in PATH entries.

.DESCRIPTION
    Trims whitespace, resolves a real filesystem path when possible, and returns a consistent
    path format without a trailing backslash. If the path does not exist, it is still converted
    to a full absolute path relative to the current working directory.
    Variables are preserved (but not expanded).

.PARAMETER LiteralPath
    The path to normalize.

.OUTPUTS
    System.String
    Returns the normalized absolute path.

.EXAMPLE
    Resolve-EnvPath ".\tools\bin"

    Description:
    Converts the relative path to an absolute path.

.EXAMPLE
    Resolve-EnvPath "C:\Tools\bin\"

    Description:
    Returns a normalized version without the trailing backslash.

.EXAMPLE
    Resolve-EnvPath "C:\This\Folder\Does\Not\Exist"

    Description:
    Returns the absolute full path even if it does not currently exist.
#>
function Resolve-EnvPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Alias('literalPath')]
        [string[]]$path
    )

    begin {
        $resolved = @()
    }

    process {
        foreach ($p in $path) {
            $p = $p.Trim('"`t ')

            # Keep absolute paths and variables untouched
            if ([IO.Path]::IsPathRooted($p) -or ($p -like '%*')) {
                $resolved += $p.TrimEnd('\')
                continue
            }

            # If it exists, resolve it fully.
            if (Test-Path -Literal $p) {
                $fullPath = (Resolve-Path -Literal $p).ProviderPath
                $resolved += $fullPath.TrimEnd('\')
                continue
            }

            # If it doesn't exist, still normalize it relative to current location.
            $fullPath = [IO.Path]::GetFullPath($p)
            if ($fullPath.Length -gt 3 -and $fullPath.EndsWith('\')) {
                $fullPath = $fullPath.TrimEnd('\')
            }

            $resolved += $fullPath
        }
        return $resolved
    }
}

<#
.SYNOPSIS
    Gets matching paths from the PATH environment variable.

.DESCRIPTION
    Returns any occurrence of the searched directory name or path in the PATH variable.
    If path is relative, resolves it to the current working directory
    (PATH contains only absolute paths).
    If parameters are omitted, returns all paths.

.PARAMETER Path
    Full or relative path or name of the file.

.PARAMETER Scope
    The PATH scope to search in.

    Valid values:
    - Session: searches only the current PowerShell session PATH
    - User: searches the current user's PATH
    - Machine: searches the system-wide PATH (may require elevated permissions)

.INPUTS
    System.String[]

.OUTPUTS
    System.String[]
    Returns full path(s) found in the selected PATH scope or empty array if nothing was found.

.EXAMPLE
    path notepad
    C:\Windows\system32\notepad

.EXAMPLE
    path conemu-maximus5 -Scope User
    C:\Users\ToYu\cmder\vendor\conemu-maximus5

.EXAMPLE
    path C:\Users\ToYu\cmder\vendor\conemu-maximus5

    Description:
    If path exists in PATH variable, returns it. Otherwise returns empty array.
#>
function Get-EnvPath {
    [CmdletBinding()]
    [Alias('path', 'finddir', 'findfolder')]

    param(
        [Parameter(ValueFromPipeline)]
        [AllowEmptyCollection()]
        [Alias('name', 'literalPath')]
        [string[]]$path = @(),

        [ValidateSet('Session', 'User', 'Machine')]
        [string]$scope = 'Session'
    )

    begin {
        $rawPath = switch ($scope) {
            'Session' {
                $env:Path
            }
            'User' {
                [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::User)
            }
            'Machine' {
                [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine)
            }
        }

        $envPaths = if ([string]::IsNullOrWhiteSpace($rawPath)) {
            @()
        } else {
            $rawPath -split ([IO.Path]::PathSeparator) |
                Where { -not ([string]::IsNullOrWhiteSpace($_)) } |
                ForEach { $_.Trim() } |
                Select -Unique
        }

        $matches  = @()
    }

    process {
        if (-not $path -or -not $envPaths) {
            return $envPaths
        }

        foreach ($p in $path) {
            if ([string]::IsNullOrWhiteSpace($p)) {
                continue
            }

            $isPathLike = [IO.Path]::IsPathRooted($p)
            $resolved = $isPathLike ? (Resolve-EnvPath $p) : ''
            $isFound  = $false

            foreach ($envPath in $envPaths) {
                if ($isPathLike) {
                    # Search for exact path
                    if ($envPath -ieq $resolved) {
                        $matches += $envPath
                        $isFound  = $true
                    }
                    continue
                }

                # Find all possible matches
                $name = [IO.Path]::GetFileName($p)
                $base = [IO.Path]::GetFileNameWithoutExtension($p)

                $envName = [IO.Path]::GetFileName($envPath)
                $envBase = [IO.Path]::GetFileNameWithoutExtension($envPath)

                if (
                    $envName -ieq $name -or
                    $envBase -ieq $base -or
                    $envName -like "$name*" -or
                    $envBase -like "$base*"
                ) {
                    $matches += $envPath
                    $isFound  = $true
                }
            }
            if (-not $isFound) {
                Write-Error "No matching entry found for `"$p`" in $scope PATH" -category 'ObjectNotFound'
            }
        }
        return $matches
    }
}

<#
.SYNOPSIS
    Finds files from the PATH environment variable.

.DESCRIPTION
    Returns any occurrence of the searched filename in the folders contained in the PATH variable.
    Provides more flexibility in selecting which executable to run instead of relying on
    Windows' first-match behavior when typing an executable name in the CLI or a script.

.NOTES
    Unlike other functions (like Get-Env*) in this function the path should exist on the disk.
    Otherwise it returns empty string.

.PARAMETER Name
    Name of the executable file to search for.

.PARAMETER Scope
    The PATH scope to search in.

    Valid values:
    - Session: searches only the current PowerShell session PATH
    - User: searches the current user's PATH
    - Machine: searches the system-wide PATH (may require elevated permissions)

.INPUTS
    System.String[]

.OUTPUTS
    System.String[]
    Returns full path(s) to matching executable file(s) found in the selected PATH scope.

.EXAMPLE
    Find-EnvPath notepad.exe
    C:\Windows\system32\notepad.exe

.EXAMPLE
    Find-EnvPath conemu64 -Scope User
    C:\Users\ToYu\cmder\vendor\conemu-maximus5\conemu64.exe

.EXAMPLE
    "conemu", "git" | Find-EnvPath

    Description:
    Search for all matching executables

.EXAMPLE
    Find-EnvPath pwsh -Scope Machine

    Description:
    Search the system PATH for PowerShell executables

.EXAMPLE
    Find-EnvPath C:\Windows\system32\notepad.exe
    Find-EnvPath C:\Users\ToYu\cmder

    Description:
    It can be used to check if path is present in environment

.EXAMPLE
    Find-EnvPath "cmder" | ForEach { Get-HelpMessage $_ }

    Description:
    Retrieves help information for all matching paths

.EXAMPLE
    Find-EnvPath git, gitbutler, but | Split-Path -Parent | Remove-EnvPath

    Description:
    Removes all paths to the VCS applications.

.LINK
    Get-EnvPath
    Get-HelpMessage
#>
function Find-EnvPath {
    [CmdletBinding()]
    [Alias('findfile')]

    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$name,

        [ValidateSet('Session', 'User', 'Machine')]
        [string]$scope = 'Session'
    )

    process {
        foreach ($n in $name) {
            if ([string]::IsNullOrWhiteSpace($n)) {
                continue
            }

            Get-EnvPath -scope $scope |
            ForEach {
                # Search for files matching the name with any extension
                Get-ChildItem -Path $_ -Filter "$n*" -File   |
                    Where { $n -like "$($_.BaseName)*" }
            } | Select -ExpandProperty FullName
        }
    }
}


function Update-Environment([int]$TimeoutMs = 50) {
    Add-Type @'
using System;
using System.Runtime.InteropServices;

public static class NativeMethods {
    public const uint WM_SETTINGCHANGE = 0x001A;
    public const uint SMTO_ABORTIFHUNG = 0x0002;

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern IntPtr SendMessageTimeout(
        IntPtr hWnd,
        uint Msg,
        IntPtr wParam,
        string lParam,
        uint fuFlags,
        uint uTimeout,
        out IntPtr lpdwResult);
}
'@

    $result = [IntPtr]::Zero
    [void][NativeMethods]::SendMessageTimeout(
        [IntPtr]0xFFFF,
        [NativeMethods]::WM_SETTINGCHANGE,
        [IntPtr]::Zero,
        'Environment',
        [NativeMethods]::SMTO_ABORTIFHUNG,
        $TimeoutMs,
        [ref]$result
    )
}

<#
.SYNOPSIS
    Sets an environment variable in the selected scope.

.DESCRIPTION
    Writes the environment variable to either the current session, the current user profile,
    or the machine-wide environment. If the value is empty, the variable is removed.

.PARAMETER Name
    The name of the environment variable to set or remove.

.PARAMETER Value
    The value to assign. Use an empty string to remove the variable.

.PARAMETER Scope
    The scope in which to update the value.

    Valid values:
    - Session: affects only the current session
    - User: affects the current user's future sessions
    - Machine: affects the system-wide (may require elevation)

.NOTES
    The original .NET/Windows implementation of SetEnvironmentVariable is slow because it
    broadcasts a system-wide environment change via WM_SETTINGCHANGE and waits for ALL PROCESSES
    to process it. This can block for roughly 20 seconds or more, which is why
    calls appear sluggish when updating PATH or other environment values.

    This function avoids that slow broadcast path by writing directly to the registry and by updating `$env:` for the current session.
    It then calls Update-Environment.

.EXAMPLE
    Set-EnvironmentVariable Path -Value "C:\Users\ToYu\ripgrep;C:\Users\ToYu\Notepad++" -Scope User

.EXAMPLE
    Set-EnvironmentVariable JAVA_HOME -Value C:\oracle\jdk\bin -Scope Session
#>
function Set-EnvironmentVariable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$name,

        [Parameter(ValueFromPipeline)]
        [AllowEmptyString()]
        [object]$value,

        [Parameter()]
        [ValidateSet('Session', 'User', 'Machine')]
        [string]$scope = 'User'
    )

    $ErrorAction = if ($PSBoundParameters.ContainsKey('ErrorAction')) {
        $PSBoundParameters['ErrorAction']
    } else {
        $ErrorActionPreference
    }

    switch ($scope) {
        'Session' {
            if ([string]::IsNullOrEmpty([string]$value)) {
                Remove-Item -path "Env:$name" -ErrorAction $ErrorAction
            } else {
                Set-Item -path "Env:$name" -value $value -ErrorAction $ErrorAction
            }
            return
        }
        'User' {
            $hive = 'HKCU:\Environment'
        }
        'Machine' {
            $hive = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
        }
    }

    if ([string]::IsNullOrEmpty([string]$value)) {
        Remove-ItemProperty -path $hive -name $name -ErrorAction $ErrorAction
    } else {
        $type = if ($name -ieq 'Path') {
            # Preserve variables
            [Microsoft.Win32.RegistryValueKind]::ExpandString
        } else {
            [Microsoft.Win32.RegistryValueKind]::String
        }

        Set-ItemProperty -path $hive -name $name -value $value -type $type -force -ErrorAction $ErrorAction
    }

    Update-Environment
}

<#
.SYNOPSIS
    Adds a folder to the selected PATH scope.

.DESCRIPTION
    Resolves the provided path, normalizes it, and appends it to the PATH variable for the
    requested scope if it does not already exist. The current session PATH is updated immediately.

.NOTES
    Non-executable files and variables are preserved (but not expanded).
    Usually, adding files has no effect, so use Add-EnvExe instead.
    The target path does not have to exist on the disk.

.PARAMETER Path
    The folder path to add.
    If path is relative, resolves it to the current working directory.
    Variables and files (except for executables) are preserved.

.PARAMETER Scope
    The PATH scope to modify.

    Valid values:
    - Session: affects only the current session
    - User: affects the current user's future sessions
    - Machine: affects the system-wide PATH (may require elevation)

.OUTPUTS
    System.String[]
    Returns the normalized path(s) that was added.

.EXAMPLE
    Add-EnvPath C:\Users\ToYu\ripgrep

    Description:
    Adds the folder to the current user's PATH

.EXAMPLE
    Add-EnvPath -Path .\Microsoft\WindowsApps -Scope Session

    Description:
    Resolves relative path to folder and adds it only to the current PowerShell session

.EXAMPLE
    Add-EnvPath -Path C:\Users\ToYu\Notepad++\notepad++.exe -Scope Machine

    Description:
    Adds the executable to the machine-wide PATH

.LINK
    Find-EnvPath git -Scope User | Add-EnvExe -Scope Machine

    Description:
    Finds the git.exe in the PATH (if present) and makes it available it for all users.
#>
function Add-EnvPath {
    [CmdletBinding()]
    [Alias('addpath')]

    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Alias('literalPath')]
        [string[]]$path,

        [ValidateSet('Session', 'User', 'Machine')]
        [string]$scope = 'User'
    )

    begin {
        # Values are writed separately for the current session ($env:Path)
        # and for the specified scope (environment)
        $isSessionOnly = ($scope -ieq 'Session')
        $sessionPaths  = Get-EnvPath -scope 'Session'
        $envPaths      = $isSessionOnly ? @() : (Get-EnvPath -scope $scope)
        $sessionValues = @()
        $envValues     = @()

        function Write-Err([string]$msg) {
            $extra = if ($p -ieq $resolved) {
                "`"$p`""
            } else {
                "`"$p`" -> `"$resolved`""
            }
            Write-Error "$($msg): $extra" -CategoryActivity 'Add-EnvPath' -category 'InvalidData'
        }
    }

    process {
        foreach ($p in $path) {
            if ([string]::IsNullOrWhiteSpace($p)) {
                continue
            }

            $resolved = Resolve-EnvPath $p
            $ext = [IO.Path]::GetExtension($resolved)

            if ($ext -and ($ext -match '^\.?(exe|cmd|bat|ps1|dll|com)$')) {
                Write-Err 'Specify the directory containing the file, not the file itself'
                continue
            }

            if ($resolved -notin $sessionPaths) {
                $sessionValues += $resolved
            } elseif ($isSessionOnly) {
                # Current session supposed to be updated explicitly
                Write-Err 'Path already exists in current session'
            }
            if ($isSessionOnly) {
                continue
            }

            # Persistent path
            if ($resolved -notin $envPaths) {
                $envValues += $resolved
            } else {
                Write-Err "Path already exists in $scope PATH"
            }
        }
    }

    end {
        if ($sessionValues.count) {
            $env:Path = `
                @((Get-EnvPath -scope 'Session'), $sessionValues) |
                Join-String -sep ([IO.Path]::PathSeparator)
        }
        if ($isSessionOnly) {
            return $sessionValues
        }

        if ($envValues.count) {
            @((Get-EnvPath -scope $scope), $envValues) |
                Join-String -sep ([IO.Path]::PathSeparator) |
                Set-EnvironmentVariable 'Path' -scope $scope
        }
        return $envValues
    }
}

<#
.SYNOPSIS
    Removes a folder from the selected PATH scope.

.DESCRIPTION
    Resolves the provided path and removes all matching entries from the selected PATH scope.
    If the path is not present, the function returns false without changing the PATH.

.PARAMETER Path
    The path to remove.
    If path is relative, resolves it to the current working directory.
    If only a name is provided, removes all matches.

.PARAMETER Scope
    The PATH scope to update.

    Valid values:
    - Session: affects only the current session
    - User: affects the current user's future sessions
    - Machine: affects the system-wide PATH (may require elevation)

.OUTPUTS
    System.String[]
    Returns all removed entries.

.EXAMPLE
    Remove-EnvPath C:\Users\ToYu\ripgrep

    Description:
    Removes the full path.

.EXAMPLE
    Remove-EnvPath ripgrep

    Description:
    Removes all matching directories.

.EXAMPLE
    Remove-EnvPath -Path .\Microsoft\WindowsApps -Scope Session

    Description:
    Removes the folder relative to cur. working dir. if it was found in the variable.

.EXAMPLE
    Find-EnvPath git, gitbutler, but | Split-Path -Parent | Remove-EnvPath

    Description:
    Removes all paths to the VCS applications.
#>
function Remove-EnvPath {
    [CmdletBinding()]
    [Alias('rempath')]

    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Alias('name')]
        [string[]]$path,

        [ValidateSet('Session', 'User', 'Machine')]
        [string]$scope = 'User'
    )

    begin {
        # Values are writed separately for the current session ($env:Path)
        # and for the specified scope (environment)
        $isSessionOnly = ($scope -ieq 'Session')
        $sessionValues = @()
        $envValues     = @()

        $ErrorAction = if ($PSBoundParameters.ContainsKey('ErrorAction')) {
            $PSBoundParameters['ErrorAction']
        } else {
            $ErrorActionPreference
        }
    }

    process {
        $sessionValues = Get-EnvPath $path 'Session' -ErrorAction ($isSessionOnly ? $ErrorAction : 'Ignore')
        if (-not $isSessionOnly) {
            $envValues = Get-EnvPath $path $scope    -ErrorAction $ErrorAction
        }
    }

    end {
        if ($sessionValues.count) {
            $env:Path = Get-EnvPath -scope 'Session' |
                Where { $_ -notin $sessionValues } |
                Join-String -sep ([IO.Path]::PathSeparator)
        }
        if ($isSessionOnly) {
            return $sessionValues
        }

        if ($envValues.count) {
            $value = Get-EnvPath -scope $scope |
                Where { $_ -notin $envValues } |
                Join-String -sep ([IO.Path]::PathSeparator) |
                Set-EnvironmentVariable 'Path' -scope $scope -ErrorAction $ErrorAction
        }
        return $envValues
    }
}

<#
.SYNOPSIS
    Repairs the PATH value for the selected scope.

.DESCRIPTION
    Normalizes PATH entries by trimming quotes and whitespace, removes empty values,
    and optionally keeps only entries that exist or are directories.

.PARAMETER scope
    The scope to repair.

    Valid values:
    - Session: affects only the current session
    - User: affects the current user's future sessions
    - Machine: affects the system-wide PATH (may require elevation)

.PARAMETER exists
    If specified, removes entries that do not exist on disk.

.PARAMETER folders
    If specified, keeps only directory entries.

.EXAMPLE
    Repair-EnvPath -scope User

.EXAMPLE
    Repair-EnvPath -scope Machine -exists

.EXAMPLE
    Repair-EnvPath -scope Session -folders
#>
function Repair-EnvPath {
    [CmdletBinding()]
    param(
        [ValidateSet('Session', 'User', 'Machine')]
        [string]$scope = 'User',

        [Alias('strict')]
        [switch]$exists,

        [Alias('dir', 'dirs', 'directories')]
        [switch]$folders
    )

    Get-EnvPath -scope $scope |
        ForEach { $_.Trim('"/\`t ') } |
        Where {
            $_ -and
            (-not $exists  -or (Test-Path -Literal $_)) -and
            (-not $folders -or (Test-Path -Literal $_ -PathType Container))
        } |
        Select -Unique |
        Join-String -sep ([IO.Path]::PathSeparator) |
        Set-EnvironmentVariable 'Path' -scope $scope
}