function Get-WindowsVersion {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class WinBrand {
    [DllImport("winbrand.dll", CharSet = CharSet.Unicode)]
    public static extern IntPtr BrandingFormatString(string fmt, string win);

    public static string Brand(string fmt, string win) {
        return Marshal.PtrToStringUni(BrandingFormatString(fmt, win));
    }
}
'@

    $r = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\'

    [PSCustomObject]@{
        ProductName    = [WinBrand]::Brand("%WINDOWS_LONG%", "%WINDOWS_LONG%")
        DisplayVersion = $r.DisplayVersion
        EditionID      = $r.EditionID
        ReleaseID      = $r.ReleaseID
        Build          = "$($r.CurrentBuild).$($r.UBR)"
        BuildBranch    = $r.BuildBranch
        InstalledUTC   = ([datetime]"1/1/1601").AddTicks($r.InstallTime)
        Computername   = $env:ComputerName
    }
}

function Get-WindowsVersionString {
    Get-WindowsVersion | ForEach {
        "{3} {0} Version {1} (OS Build {2})" -f $_.ProductName, $_.EditionID, $_.Build, $_.Computername
    }
}

function Get-PowershellVersionString {
    "{0}" -f $PsVersionTable.PsVersion
}

function Get-AliasTable {
    Get-Alias | ForEach-Object {
        [PSCustomObject]@{
            Alias    = $_.Name
            Function = $_.Definition
            Source   = $_.Source
        }
    } | Format-Table -AutoSize
}

Set-Alias  winver   Get-WindowsVersion
Set-Alias  about    Get-WindowsVersionString
Set-Alias  psver    Get-PowershellVersionString
Set-Alias  aliases  Get-AliasTable

<#
.SYNOPSIS
    Writes a detailed message string.

.DESCRIPTION
    This command is designed to be used within your functions and scripts 
    to make it easier to write a detailed message that you can use 
    as verbose output. The assumption is that you are using an advanced 
    function with Begin, Process, and End scriptblocks. You can create a 
    detailed message to indicate what part of the code is being executed. 
    The output can include a full-time stamp, or a time string which 
    includes a millisecond value.

.NOTES
    In a script you might use it like this in a Begin block:

    $pfx = "BEGIN"
    Write-Detail "Starting $($MyInvocation.MyCommand)" -Prefix $pfx | Write-Verbose
    Write-Detail "PS $($PSVersionTable.PSVersion)" -Prefix $pfx | Write-Verbose

    If you don't specify a prefix, it will default to PROCESS.

.PARAMETER Message
    The message to display after the time stamp and prefix.

.PARAMETER Prefix
    Indicate whether you are in the BEGIN, PROCESS, or END script block. 
    Although you can specify any text. It will be displayed in upper case.

.PARAMETER Date
    Display a date value like 9/15/2024 11:36:41.

.PARAMETER Time
    Display a time value with milliseconds like 11:37:01:4029.

.EXAMPLE
    PS C:\> Write-Detail "Getting file information" -Prefix Process
    [PROCESS] Getting file information

    Description:
    Normally you would use this command in a function, but here is an example 
    from the console so that you can see what to expect.

.EXAMPLE
    PS C:\> Write-Detail -message "Initializing variables" -Prefix Begin -time
    01:25:29:8700 [BEGIN] Initializing variables
#>
function Write-Detail {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    Param(
        [Parameter(Position = 0, Mandatory)]
        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Date")]
        [Parameter(ParameterSetName = "Time")]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Date")]
        [Parameter(ParameterSetName = "Time")]
        [string]$Prefix = "PROCESS",

        [Parameter(ParameterSetName = "Date")]
        [switch]$Date,
        [Parameter(ParameterSetName = "Time")]
        [Switch]$Time
    )

    if ($time) {
        $dt = (Get-Date -Format "hh:mm:ss:ffff")
    } elseif ($Date) {
        $dt = "{0} {1}" -f (Get-Date).ToShortDateString(), (Get-Date -Format "hh:mm:ss")
    }

    if ($PSCmdlet.ParameterSetName -eq 'Default') {
        $Text = "[$($prefix.ToUpper())] $Message"
    } else {
        $Text = "$dt [$($prefix.ToUpper())] $Message"
    }

    return $Text
}

<#
.SYNOPSIS
    Prints a message to the console and writes it to a file.

.DESCRIPTION
    This command is designed for simple messages logging. 
    It doesn't requires multiple parameters per each call, only the message.

    If a path to a file to write to was not specified, it will be created 
    automatically with the current date in .log format and all subsequent 
    calls to Write-Log will write messages to this file.

.NOTES
    To fully control the output use Write-Detail and Out-VerboseTee.

.PARAMETER Message
    The message to display after the time stamp and prefix.

.PARAMETER Level
    Prefix that will be displayed before the message. 
    You can specify any text. It will be displayed in upper case.

.PARAMETER LogFullPath
    Display a date value like 9/15/2024 11:36:41.

.EXAMPLE
    Write-Log 'Tracing script'
    12:13:00 [INFO]  Tracing script

.EXAMPLE
    Write-Log 'Tracing script' 'Debug' 'trace.log'
    12:21:41 [DEBUG]  Tracing script

.EXAMPLE
    Get-WindowsVersion | ConvertTo-Json | Write-Log

    Description:
    Dumps information about current system to the generated log.

.EXAMPLE
    (&"C:\Program Files\7-Zip\7z.exe" l z.zip) | Out-String | Write-Log

    Description:
    List files inside z.zip, print them to console and write to the log.

.EXAMPLE
    Write-Log 'Tracing script' 'Info' 'info.log'
    Write-Log 'Init variables' 'Info'  <-- writes to info.log
    Write-Log 'Create objects' 'Info'  <-- writes to info.log
    Write-Log 'Wrong files' 'Warning' 'warns.log'
    Write-Log 'Locked file' 'Warning'  <-- writes to warns.log
    
    Description:
    You can override the file for all subsequent calls

.LINK
    Out-VerboseTee
.LINK
    Write-Detail
.LINK
    ConvertTo-Json
#>
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0, ValueFromPipeline)]
        [string]$message,

        [Parameter(Position=1)]
        [string]$level = 'Info',

        [Parameter(Position=2)]
        [string]$logFullPath
    )

    begin {
        if($PSBoundParameters.ContainsKey('logFullPath')) {
            $script:logPath = $logFullPath
            Write-Debug "Recievied path to log: `"$($script:logPath)`""
        } elseif (-not (Test-Path variable:logPath)) {
            New-Variable logPath ("{0}.log" -f (Get-Date -format 'yyyy-MM-dd HH.mm.ss')) `
                -Scope Script -Visibility Private

            Write-Debug "Generated log: `"$($script:logPath)`""
        }
    }

    process {
        switch ($level) {
        'Verbose' {
            $isOutput = ($VerbosePreference -ne 'SilentlyContinue')
            $color = 'Cyan'
        }
        'Debug'   {
            $isOutput = ($DebugPreference   -ne 'SilentlyContinue')
            $color = 'DarkGray'
        }
        'Warning' {
            $isOutput = ($WarningPreference -ne 'SilentlyContinue')
            $color = 'Yellow'
        }
        'Error'   {
            $isOutput = ($ErrorActionPreference -ne 'SilentlyContinue')
            $color = 'Red'
        }
        default   {
            $isOutput = !$silent
            $color = 'White'
        }
        }

        $level = '[{0}]' -f $level.ToUpper()
        $date  = Get-Date -Format 'hh:mm:ss'

        if ($isOutput) {
            Write-Host   $date      -f DarkGray -n
            Write-Host " $level "   -f $color   -n
            Write-Host " $message"  -f $color
        }
    }

    end {
        ('{0} {1} {2}' -f $date, $level, $message) | Out-File -Append -FilePath $script:logPath
    }
}

<#
.SYNOPSIS
    Writes to the Verbose stream and a file.

.DESCRIPTION
    This command is intended to let you see your verbose output and write the 
    verbose messages to a log file. It will only work if the verbose pipeline 
    is enabled, usually when your command is run with -Verbose. This function 
    is designed to be used within your scripts and functions. You either have 
    to hard code a file name or find some other way to define it in your 
    function or control script. You could pass a value as a parameter or set 
    it as a PSDefaultParameterValue.

    When the command is run with -Verbose you will see the verbose output and 
    it will be saved to the specified log file.

.PARAMETER Append
    Append to the specified text file.

.PARAMETER Encoding
    Specify a file encoding.

.PARAMETER Path
    The path for the output file.

.PARAMETER Value
    The message to be displayed as a verbose message and saved to the file.

.EXAMPLE
    PS C:\> $VerbosePreference= "continue"
    PS C:\> $log = New-CustomFileName ".\VerboseLog_%time.txt"
    PS C:\> Write-Detail "This is a verbose log test" | Out-VerboseTee -Path $log
    PS C:\> Get-Content $log
    11/29/2024 08:21:31:0704 [PROCESS] This is a verbose log test
    PS C:\> $verbosePreference = "SilentlyContinue"
    Normally you would use this command inside a function or script, 
    but you can run it from the console if you want to understand how it works.
#>
function Out-VerboseTee {
    [CmdletBinding()]
    [Alias("log", "stdout")]

    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$Value,
        [Parameter(Position = 0, Mandatory)]
        [string]$Path,
        [System.Text.Encoding]$Encoding,
        [switch]$Append
    )
    
    begin {
        # turn on verbose pipeline since if you are running this command you intend for it to be on
        $VerbosePreference = "continue"
    }
    
    process {
        # only run if Verbose is turned on
        if ($VerbosePreference -eq "continue") {
            $Value | Out-String | Write-Verbose
            [void]$PSBoundParameters.Remove("Append")

            if ($Append) {
                Add-Content @PSBoundParameters
            } else {
                Set-Content @PSBoundParameters
            }
        }
    }
    
    end {
        $VerbosePreference = "SilentlyContinue"
    }
}

<#
.SYNOPSIS
    Sends "pages" of objects to the pipeline.

.DESCRIPTION
    This function is designed to display groups or "pages" of objects to the PowerShell 
    pipeline. It is modeled after the legacy `more` command-line utility. By default, 
    the command will write objects out to the pipeline in groups of 50. You will be 
    prompted after each grouping.

    Pressing M or Enter will get the next group. Pressing A will stop paging and display 
    all of the remaining objects. Pressing N will display the next object. Press Q to 
    stop writing anything else to the pipeline.

.NOTES
    Note that you may encounter an error message when quitting prematurely, especially 
    on non-Windows platforms. You can ignore these errors.

.PARAMETER InputObject
    Specifies the objects to be sent to the pipeline.

.PARAMETER Count
    The number of objects to group as a page.

.PARAMETER ClearScreen
    Clear the screen before writing data to the pipeline.

    Type: SwitchParameter
    Parameter Sets: (All)
    Aliases: cls

    Required: False
    Position: Named
    Default value: False
    Accept pipeline input: False
    Accept wildcard characters: False

.EXAMPLE
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
    Display processes in groups of 10.

.EXAMPLE
    PS C:\> dir c:\work -file -Recurse | more -ClearScreen | log -Variable work
    List all files in C:\Work and page them to Out-More using the default count, 
    but after clearing the screen first. The results are then piped to Tee-Object 
    which saves them to a variable.
#>
function Out-More {
    [CmdletBinding()]
    [Alias("more", "detailed")]

    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object[]]$InputObject,
        [ValidateRange(1, 1000)]
        [Alias("i")]
        [int]$Count = 50,
        [Alias("cls")]
        [Switch]$ClearScreen
    )

    begin {
        if ($ClearScreen) {
            Clear-Host
        }

        #initialize an array to hold objects
        $data = @()

        #initialize some variables to control flow
        $ShowAll = $False
        $ShowNext = $False
        $Ready = $False
        $Quit = $False

    }

    process {
        if ($Quit) {
            Write-Verbose "Quitting"
            break
        } elseif ($ShowAll) {
            $InputObject
        } elseif ($ShowNext) {
            Write-Verbose "Show Next"
            $ShowNext = $False
            $Ready = $True
            $data = , $InputObject
        } elseif ($data.count -lt $count) {
            Write-Verbose "Adding data"
            $data += $InputObject
        } else {
            #write the data to the pipeline
            $data
            #reset data
            $data  = , $InputObject
            $Ready = $True
        }

        if ($Ready) {
            #pause
            do {
                Write-Host "[M]ore [A]ll [N]ext [Q]uit " -ForegroundColor Green -NoNewline
                $r = Read-Host
                if ($r.Length -eq 0 -or $r -match "^m") {
                    #don't really do anything
                    $Asked = $True
                } else {
                    switch -regex ($r) {
                        "^n" {
                            $ShowNext = $True
                            $InputObject
                            $Asked = $True
                        }
                        "^a" {
                            $InputObject
                            $Asked = $True
                            $ShowAll = $True
                        }
                        "^q" {
                            #bail out
                            $Asked = $True
                            $Quit = $True
                        }
                        default {
                            $Asked = $False
                        }
                    }

                }
            } until ($Asked)

            $Ready = $false
            $Asked = $false
        }
    }

    end {
        # test if data is from a get-help command in
        # which case it will be a single string that needs
        # to be broken apart

        if ([regex]::Matches($data, "`n").count -gt 1) {
            [void]$PSBoundParameters.remove("InputObject")
            $data.split("`n") | Out-More @PSBoundParameters
        } elseif ($data[0].PSObject.TypeNames -contains "MamlCommandHelpInfo") {
            [void]$PSBoundParameters.remove("InputObject")
            ($data | Out-String).split("`n") | Out-More @PSBoundParameters
        }

        #display whatever is left in $data
        if ($data -and -not $ShowAll) {
            Write-Verbose "Displaying remaining data"
            return $data
        }
    }
}

<#
.SYNOPSIS
    Escapes arguments.

.DESCRIPTION
    Converts list of arguments (array of strings) to properly escaped string of arguments.

.PARAMETER Argument
    Array of stings with arguments values
#>
function ConvertTo-EscapedArguments {
    [CmdletBinding()]
    [Alias('escape')]
    
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [Alias('arg')]
        [string[]]$argument
    )
    
    begin {
        $escapedArgs = [System.Collections.Generic.List[string]]@()
    }

    process {
        foreach ($arg in $argument) {
            <# 
            stdlib Rules: 
            2N backslashes + " ==> N backslashes and begin/end quote
            2N+1 backslashes + " ==> N backslashes + literal " 
            N backslashes ==> N backslashes
            
            https://docs.microsoft.com/en-gb/windows/desktop/api/shellapi/nf-shellapi-commandlinetoargvw
            https://stackoverflow.com/questions/21314633/how-do-i-pass-a-literal-double-quote-from-powershell-to-a-native-command
            #>
            # escaping double quotes as we use them to indicate start/end of argument
            $arg = $arg.Replace('"', '\"')

            # double all the slashes followed by \" 
            # (no more org before quote, so quote is never end/begin arg char)
            $arg = $arg -replace '(\\+)\\\"', '$1$1\"'

            # double all the slashes at the end of the argument
            $arg = $arg -replace '(\\+)$', '$1$1'

            # wrapping argument
            $escapedArgs.Add("`"$arg`"")
        }
        return ($escapedArgs -join ' ')
    }
}

<#
.SYNOPSIS
    Retrieves help information for PowerShell commands or external applications.

.DESCRIPTION
    For built-in PowerShell commands (Cmdlet, Function, Alias), it uses the standard Get-Help function.
    For external applications, it automatically tries various help parameter variants
    (--help, -h, /?, etc.), eliminating the need to remember application-specific help syntax.

.PARAMETER command
    The name of the Cmdlet, Function, Alias, full or relative path to the application 
    or app name from PATH enviromental variable.

.PARAMETER arguments
    Arguments or sub-commands to pass to the command. If command is PowerShell command 
    (Cmdlet, Function, Alias), pass arguments for Get-Help command that will be used to 
    retrieve help message or specific details about this command.

.INPUTS
    System.String
    You can pipe file name or path to this function.

.OUTPUTS
    System.String
    Returns the help text for the command or application.

.EXAMPLE
    hlp Get-Process

    Description:
    Retrieves help for the built-in PowerShell command Get-Process.
    Equivalent to running Get-Help Get-Process.

.EXAMPLE
    hlp pip

    Description:
    Retrieves commands for the Python package manager.

.EXAMPLE
    hlp pip install

    Description:
    Retrieves help for the 'install' sub-command of Python package manager.
    
.EXAMPLE
    hlp "C:\Program Files\Git\cmd\git.exe"

    Description:
    Retrieves help information for the git VCS.

.EXAMPLE
    hlp Stop-HiddenScript -Parameter launcher

    Description:
    Retrieves detailed information about 'launcher' param.

.LINK
    Get-Help

.LINK
    Get-Command
#>
function Get-HelpMessage {
    [CmdletBinding()]
    [Alias('hlp', 'h')]

    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$command,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$arguments = @()
    )

    begin {
        [string[]]$helpParams = @('--help', '-help', 'help', '-h', '--h', '-?', '/help', '/h', '/?')
        # [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    }

    process {
        $commandObj = Get-Command $command -CommandType Application -ErrorAction Ignore |
            Select-Object -First 1
        
        if ($commandObj -or (Test-Path $command)) {
            # Pass help arguments one by one.
            # Pass additional args if needed.
            $params = $arguments.count ? (ConvertTo-EscapedArguments $arguments) : ''
            
            # Prepare process launch
            $proc = New-Object System.Diagnostics.Process
            $proc.StartInfo = [System.Diagnostics.ProcessStartInfo]@{
                FileName = $commandObj.source   # Full path to the binary
                # StandardOutputEncoding = [System.Text.Encoding]::UTF8
                # StandardErrorEncoding  = [System.Text.Encoding]::UTF8
                RedirectStandardError  = $true
                RedirectStandardOutput = $true
                UseShellExecute        = $false  # no visible shell
                WorkingDirectory       = (Get-Location).path 
            }
            
            ForEach ($help in $helpParams) {
                $proc.StartInfo.Arguments = "$params $help"
                $proc.Start() | Out-Null
                
                $output = $proc.StandardOutput.ReadToEnd()
                $proc.WaitForExit()

                if (!$proc.ExitCode) {
                    return $output
                }
            }
            
            Write-Error ($proc.StandardError.ReadToEnd())
            return
        }
        
        if (!$arguments.Count) {
            return (Get-Help $command)
        }

        # Parse arguments for Get-Help
        $params = @{}
        $i = 0;
        while ($i -lt $arguments.Count) {
            $key = $arguments[$i].Trim('-/" ')
            $val = $arguments[$i + 1]

            if ($val -and $val -notmatch '^[/-]') {
                # Next value is not a switch or named param
                $params[$key] = $val
                $i += 2
            } else {
                # No value provided, assume it's a switch
                $params[$key] = $true
                $i++
            }
        }

        Get-Help $command @params
    }
}

<#
.SYNOPSIS
    Extracts syntax for PowerShell commands or external applications.

.DESCRIPTION
    Extracts and pretty-prints syntax for PowerShell commands 
    (Cmdlet, Function, Alias) and external applications.

.PARAMETER command
    The name of the Cmdlet, Function, Alias, full or relative path to 
    the application or app name from PATH enviromental variable.

.PARAMETER arguments
    Additional arguments to pass to external application for retrieving 
    raw help message with syntax.

.INPUTS
    System.String
    Command name or path.

.OUTPUTS
    System.String
    Returns extracted syntax.

.NOTES
    Parameter notation in PowerShell syntax:

    [[-name] <val>]  - optional parameter, can be used by position or name
    [-name <val>]    - optional parameter, can only be used by name
    [-name] <val>    - required parameter, can be used by position or name
    -name <val>      - required parameter, can only be used by name
    [-name]          - switch parameter (always optional, only by name)

.EXAMPLE
    usage Get-Command

    Description:
    Displays all ParameterSets for Get-Command with formatted parameters.

.EXAMPLE
    usage ls

    Description:
    Resolves the 'ls' Alias to Get-ChildItem and shows its syntax.

.EXAMPLE
    usage pip

    Description:
    Extracts 'usage' section from Python package manager help output.

.EXAMPLE
    usage pip install

    Description:
    Extracts syntax for the 'install' sub-command of Python package manager.

.EXAMPLE
    usage "C:\Program Files\Git\cmd\git.exe"

    Description:
    Extracts syntax for the git.exe.

.LINK
    Get-Command

.LINK
    Get-Help

.LINK
    Get-HelpMessage

.LINK
    about_Command_Syntax
#>
function Get-HelpSyntax {
    [CmdletBinding()]
    [Alias('?!', 'syntax', 'usage')]

    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$command,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$arguments = @()
    )

    # Extract from external app
    if ((Test-Path $command) -or
        (Get-Command $command -CommandType Application -ErrorAction Ignore)) {
        $help = Get-HelpMessage $command $arguments
        $command = [System.IO.Path]::GetFileNameWithoutExtension($command)

        if ($help -match "(?msix) (^ (usage (?: :|\r?\n) | $command \s+) .+?) (?: \r?\n \r?\n [a-z] | \z)") {
            $matches[1].Trim() -split "`n" | ForEach {
                if ($_.StartsWith('usage')) {
                    $_.replace("usage:\s*", '')
                } else {
                    $_
                }
            }
        }
        return
    }

    # Extract from PowerShell command.
    # Resolve Alias
    if (Get-Command $command -CommandType Alias -ErrorAction Ignore) {
        $syntax = (Get-Command -syntax (Get-Command $command).ResolvedCommandName)
    } else {
        $syntax = (Get-Command -syntax $command)
    }

	$parameterSets = @((Get-Command $command).parameterSets.Name)
	$syntax = ($syntax -split ' (?=(\[{1,2}[-<]|-))' -replace '^[\[-]', '   $0').where{$_ -match '.*\w'}
	if ($parameterSets[0] -eq '__AllParameterSets') {
		return $syntax
	}

    # Get multiple parameters sets
    $syntax = (($syntax -join "`r`n").Trim() -split "($command)").where{$_.Trim() -ne ''}

    $i = 0
    $syntax | ForEach {
        if ($_.Trim() -eq $command){
            "`nParameterSet`: $($parameterSets[$i])"
            $_
            $i++
        } else {
            $_.TrimEnd()
        }
    }
}

<#
.SYNOPSIS
    Extracts examples for PowerShell commands or external applications.

.DESCRIPTION
    Extracts and pretty-prints examples for PowerShell commands 
    (Cmdlet, Function, Alias) and external applications.

.PARAMETER command
    The name of the Cmdlet, Function, Alias, full or relative path 
    to the application or app name from PATH enviromental variable.

.PARAMETER arguments
    Additional arguments to pass to external application for 
    retrieving raw help message with examples.

.INPUTS
    System.String
    Command name or path.

.OUTPUTS
    System.String
    Returns extracted examples.

.EXAMPLE
    Get-HelpExample Stop-HiddenScript

    Description:
    Displays all examples for the function.

.EXAMPLE
    Get-HelpExample kills

    Description:
    Resolves the 'kills' alias to Stop-HiddenScript and shows it's examples.

.EXAMPLE
    Get-HelpExample gh

    Description:
    Extracts syntax for the gh.exe (GitHub).

.EXAMPLE
    Get-HelpExample gh search

    Description:
    Extracts example for the 'search' sub-command of GitHub command.

.EXAMPLE
    Get-HelpExample "C:\Windows\system32\taskkill.exe"

    Description:
    Extracts examples for the taskkill.exe.

.LINK
    Get-Command

.LINK
    Get-Help

.LINK
    Get-HelpMessage

.LINK
    about_Command_Syntax
#>
function Get-HelpExample {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$command,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$arguments = @()
    )
    
    if ((Test-Path $command) -or 
        (Get-Command $command -CommandType Application -ErrorAction Ignore)) {
        # Application
        $help = Get-HelpMessage $command $arguments
        if ($help -match '(?msix) Examples? (?: :|\r?\n) (.+?) (?: \r?\n \r?\n [A-Z] | \z)') {
            $matches[1].Trim() -split "`n" | ForEach {
                if ($_) {
                    $_
                }
            }
        }
    } else {
        # Function
        $help = Get-Help $command -full
        if ($help.examples.example) {
            $help.examples.example | ForEach {
                $_.Code.Split("`n") | ForEach {
                    if ($_.StartsWith('PS C:\>')) {
                        $_.replace('PS C:\>', '')
                    } else {
                        $_
                    }
                }
            }
        }
    }
}

<#
.SYNOPSIS
    Retrieves error information based on the code.

.DESCRIPTION
    This function uses the certutil command to obtain error 
    information based on the provided code.

.PARAMETER code
    The error code for which to retrieve information.

.PARAMETER UI
    Displays a dialog box with the error description and code.

.INPUTS
    System.String
    You can pipe error code to this function.

.OUTPUTS
    None

    Outputs error message for this code.

.EXAMPLE
    Get-Error -code 0xc0000602
    Outputs the description: 
    "Exception handlers will not be invoked, the process will be terminated immediately."

.EXAMPLE
    Get-Error -code 0xc0000602 -UI
    Displays a window "An error occurred" with its number and description.
#>
function Get-Error {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$code,
        [switch]$UI
    )
    if ($UI) {
        slui 0x2a $code
    } else {
        certutil -error $code
    }
}

<#
.SYNOPSIS
    Counts the total number of lines in files within a specified path.

.DESCRIPTION
    Recursively searches for files by filter in the specified directory 
    and counts the total lines across all files.
    Displays individual file line counts and a total summary.

.PARAMETER Path
    The root path to search for. Defaults to current directory.

.PARAMETER Filter
    File filter pattern. Defaults to *.ahk.

.EXAMPLE
    Get-LineCount -Path "C:\Scripts"

.EXAMPLE
    Get-LineCount -Path "Build.ahk" -Recurse

.OUTPUTS
    PSCustomObject with properties: FullName, LineCount
#>
function Get-LineCount {
    [CmdletBinding()]
    [Alias('lines')]

    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0)]
        [string]
        $Path = ".",

        [Parameter(Mandatory = $false)]
        [string]
        $Filter = "*.ahk"
    )

    begin {
        $totalLines = 0
        $fileCount  = 0
        $results    = [System.Collections.Generic.List[PSCustomObject]]@()
        
        $ErrorAction = if ($PSBoundParameters.ContainsKey('ErrorAction')) {
            $PSBoundParameters['ErrorAction']
        } else {
            'Ignore'
        }
    }

    process {
        $files = Get-ChildItem `
            -Path $Path -Filter $Filter `
            -ErrorAction:$ErrorAction `
            -Recurse

        if (-not $files) {
            Write-Warning "No $Filter files found in `"$Path`""
            return
        }

        foreach ($file in $files) {
            $content = Get-Content -Path $file.FullName -ErrorAction:$ErrorAction

            if ($null -eq $content) {
                $lineCount = 0
            } elseif ($content -is [string]) {
                $lineCount = 1
            } else {
                $lineCount = $content.Count
            }

            $totalLines += $lineCount
            $fileCount++

            $results.Add([PSCustomObject]@{
                FullName  = $file.FullName
                LineCount = $lineCount
            })
        }
    }

    end {
        $results | Format-Table -AutoSize

        Write-Output "Total Files: $fileCount"
        Write-Output "Total Lines: $totalLines"

        # [PSCustomObject]@{
            # TotalFiles = $fileCount
            # TotalLines = $totalLines
            # Files      = $results
        # }
    }
}

<#
.SYNOPSIS
    Stops hidden running scripts by path or name.

.DESCRIPTION
    Stops running scripts by searching for hidden windows with 
    specified script paths in the title.

    You can specify full or relative paths to the scripts or 
    just filenames to find all matches using Everything search 
    tool and terminate them.

.PARAMETER names
    Specifies the paths/names of the scripts to stop.

.PARAMETER launcher
    Specifies the owner/launcher of the script (e.g., "autohotkey", "python").
    This is used to filter processes by name pattern. 
    If empty or missing, function terminates everything that was found by $names.

.PARAMETER force
    Stops the specified/found scripts without prompting for confirmation.

.PARAMETER confirm
    Prompts for confirmation before stopping each specified/found script.

.INPUTS
    System.String[]
    You can pipe script names to this function.

.OUTPUTS
    None

.EXAMPLE
    Stop-HiddenScript "C:\Script1.ahk", "C:\Script2.py"

    Description:
    Stops multiple scripts at once.

.EXAMPLE
    Stop-Script "Script1.ahk", "Script2.py" -confirm

    Description:
    Searches for scripts and prompts for confirmation before terminating each found script.

.EXAMPLE
    Stop-HiddenScript -names "Script1.py", "Script2.py" -launcher "python" -force

    Description:
    Searches for Python scripts and terminates them if they are launched using "python" process.

.NOTES
    Requirements:
    - es.exe (Everything search tool) for search method.
    - Administrative privileges may be required for some processes

    See Stop-Script for termination without search tool.

.LINK
    tasklist.exe

.LINK
    es.exe
#>
function Stop-HiddenScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$names,

        [Parameter()]
        [AllowEmptyString()]
        [string]$launcher,

        [Parameter()]
        [switch]$force,

        [Parameter()]
        [switch]$confirm
    )

    process {
        # Resolve passed names
        $scripts = @{}
        ForEach ($name in $names) {
            if (Test-Path $name) {
                $files = (Resolve-Path $name).Path
            } else {
                try {
                    $files = es.exe file:nopath:"$name" 2>$null
                } catch [System.Management.Automation.CommandNotFoundException] {
                    Write-Warning "Unable to find '$name': Everything search tool (es.exe) is not installed."
                    continue
                }
            }

            if (-not $files) {
                Write-Warning "Unable to find '$name': change the name and try again."
                continue
            }


            # Find matching scripts and get their PID
            ForEach ($file in $files) {
                # tasklist.exe params
                $params = [System.Collections.Generic.List[string]]@(
                    '-nh',                              # No table header
                    '-fo', "csv",                       # Output in CSV style
                    '-fi', "WindowTitle eq $file*"      # Search for path in WindowTitle
                )

                if ($launcher) {
                    # Process name must contain launcher name
                    $params.Add('-fi')
                    $params.Add("ImageName eq $launcher*")
                }

                # Get PIDs
                (tasklist.exe @params) | ForEach {
                    $id = ($_.Split(',').Trim('"'))[1]

                    if ($id -match '^\d+$') {
                        $scripts.Add($id, $file)
                    }
                }
            }
        }

        if (-not $scripts.count) {
            return $false
        }

        :StopScripts ForEach ($s in $scripts.GetEnumerator()) {
            :AskConfirm while ($confirm) {
                Write-Host "Terminate '" -n
                Write-Host "$($s.Value)" -f DarkCyan -n
                Write-Host "'?"

                $response = Read-Host "[Y] Yes  [A] Yes to All  [N] No  [L] No to All  [P] Pause  [?] Help (default is `"Y`")"

                :AnalyzeResponse switch ($response) {
                    'A' { $confirm = $false; break AskConfirm }
                    'Y' { break AskConfirm }
                    'N' { continue StopScripts }
                    'L' { return $false }
                    'P' { pause }

                    default {
                        Write-Host "Y - Terminate current process.`nA - Terminate all processes without prompting`nN - Skip current process.`nL - Skip all remaining processes.`nP - Pause current operation and return to the command prompt."
                        continue AskConfirm
                    }
                }
            }

            if ($force) {
                taskkill.exe -pid $s.Key -f 1>$null
            } else {
                taskkill.exe -pid $s.Key 1>$null
            }

            if ($LastExitCode -eq 0) {
                Write-Host "$launcher script '" -f DarkGray -n
                Write-Host "$($s.Value)"        -f DarkCyan -n
                Write-Host "' ($($s.Key)) is "  -f DarkGray -n
                Write-Host "terminated"         -f Green
            }
        }

        return $true
    }
}

<#
.SYNOPSIS
    Stops running scripts by name.

.DESCRIPTION
    Stops running scripts by searching for processes associated 
    with the specified script names (processes with files in command line).

    The function tries multiple methods sequentially (including Stop-HiddenScript) 
    and returns after the first successful termination method.

.PARAMETER names
    Specifies the names of the scripts to stop.

.PARAMETER launcher
    Specifies the owner/launcher of the script (e.g., "autohotkey", "python").
    This is used to filter processes by name pattern. Cannot be empty.

.PARAMETER force
    Stops the specified scripts without prompting for confirmation.

.PARAMETER confirm
    Prompts for confirmation before stopping each script.

.INPUTS
    System.String[]
    You can pipe script names to this function.

.OUTPUTS
    None

    The function outputs a formatted table of terminated processes showing Id and
    ProcessName, along with status messages indicating success or failure.

.EXAMPLE
    Stop-Script "Script1", "Script2"

    Description:
    Stops multiple AutoHotkey scripts at once.

.EXAMPLE
    Stop-Script "Script1", "Script2" -confirm

    Description:
    Prompts for confirmation before terminating each found script.

.EXAMPLE
    kills -names "Script1.py", "Script2.py" -launcher "python" -force

    Description:
    Stops a Python scripts by specifying launcher.

.LINK
    Stop-Process

.LINK
    Get-Process

.LINK
    Get-CimInstance

.LINK
    Stop-HiddenScript
#>
function Stop-Script {
    [CmdletBinding()]
    [Alias('kills', 'stop')]

    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$names,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$launcher = "autohotkey",

        [Parameter()]
        [switch]$force,

        [Parameter()]
        [switch]$confirm
    )

    begin {
        # for Stop-Process
        $params = @{
            PassThru = $true
            force    = $force
            confirm  = $confirm
        }

        function Try-Kill($id) {
            if (!$id) { return $false }

            $proc = Stop-Process -id $id @params
            if ($proc) {
                $proc | Format-Table Id, ProcessName | Out-Host

                Write-Host "$launcher script '" -f DarkGray -n
                Write-Host "$name"        -f DarkCyan -n
                Write-Host "' is "        -f DarkGray -n
                Write-Host "terminated"   -f Green

                return $true
            }

            return $false
        }

        # for getters using Where-Object
        $filter = {
            $_.Name -like "$launcher*" -and
            $_.CommandLine -like "*$name*"
        }
    }

    process {
        ForEach ($name in $names) {
            # Try different methods
            $proc = Get-Process | Where $filter
            if (Try-Kill $proc.Id) { continue }

            $proc = Get-CimInstance Win32_Process | Where $filter
            if (Try-Kill $proc.processId) { continue }

            $proc = Get-CimInstance Win32_Process -filter "name like '$launcher%' and CommandLine like '%$name%'"
            if (Try-Kill $proc.processId) { continue }

            # Fallback to Everything search
            if (Stop-HiddenScript $name $launcher -force:$force -confirm:$confirm) { continue }

            Write-Warning "Unable to find $launcher script '$name'"
        }
    }
}