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
    "{0}" -f $psversiontable.psversion
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

Set-Alias   winver      Get-WindowsVersion
Set-Alias   about       Get-WindowsVersionString
Set-Alias   psver       Get-PowershellVersionString
Set-Alias   aliases     Get-AliasTable

<#
.SYNOPSIS
    Writes a detailed message string.

.DESCRIPTION
    This command is designed to be used within your functions and scripts to make it easier to write a detailed message that you can use as verbose output. The assumption is that you are using an advanced function with Begin, Process, and End scriptblocks. You can create a detailed message to indicate what part of the code is being executed. The output can include a full-time stamp, or a time string which includes a millisecond value.

    In a script you might use it like this in a Begin block:

    $pfx = "BEGIN"
    Write-Detail "Starting $($MyInvocation.MyCommand)" -Prefix $pfx | Write-Verbose
    Write-Detail "PS $($PSVersionTable.PSVersion)" -Prefix $pfx | Write-Verbose

    If you don't specify a prefix, it will default to PROCESS.

.PARAMETER Message
    The message to display after the time stamp and prefix.

    Type: String
    Parameter Sets: (All)
    Aliases:

    Required: False
    Position: 0
    Default value: None
    Accept pipeline input: False
    Accept wildcard characters: False

.PARAMETER Prefix
    Indicate whether you are in the BEGIN, PROCESS, or END script block. Although you can specify any text. It will be displayed in upper case.

    Type: String
    Parameter Sets: (All)
    Aliases:
    Accepted values:

    Required: False
    Position: Named
    Default value: PROCESS
    Accept pipeline input: False
    Accept wildcard characters: False

.PARAMETER Date
    Display a date value like 9/15/2024 11:36:41.

    Type: SwitchParameter
    Parameter Sets: Date
    Aliases:

    Required: False
    Position: Named
    Default value: None
    Accept pipeline input: False
    Accept wildcard characters: False

.PARAMETER Time
    Display a time value with milliseconds like 11:37:01:4029.

    Type: SwitchParameter
    Parameter Sets: Time
    Aliases:

    Required: False
    Position: Named
    Default value: None
    Accept pipeline input: False
    Accept wildcard characters: False

.EXAMPLE
    PS C:\> Write-Detail "Getting file information" -Prefix Process
    [PROCESS] Getting file information
    Normally you would use this command in a function, but here is an example from the console so that you can see what to expect.

.EXAMPLE
    PS C:\> Write-Detail -message "Initializing variables" -Prefix Begin -time
    01:25:29:8700 [BEGIN] Initializing variables
#>
function Write-Detail {
    [cmdletbinding(DefaultParameterSetName = "Default")]
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
    This command is designed for simple messages logging. It doesn't requires multiple parameters per each call, only the message.

    If a path to a file to write to was not specified, it will be created automatically with the current date in .log format and all subsequent calls to Write-Log will write messages to this file.
    
    You can override the file for all subsequent calls:    
    Write-Log 'Tracing script' 'Info' 'info.log'
    Write-Log 'Init variables' 'Info'  <-- writes to info.log
    Write-Log 'Create objects' 'Info'  <-- writes to info.log
    Write-Log 'Wrong files' 'Warning' 'warns.log'
    Write-Log 'Locked file' 'Warning'  <-- writes to warns.log
    
    Для полного контроля над выводом используйте Write-Detail и Out-VerboseTee.

.PARAMETER Message
    The message to display after the time stamp and prefix.

    Type: String
    Parameter Sets: (All)
    Aliases:

    Required: True
    Position: 0
    Default value: None
    Accept pipeline input: True (ByValue)
    Accept wildcard characters: False

.PARAMETER Level
    Prefix that will be displayed before the message. You can specify any text. It will be displayed in upper case.

    Type: String
    Parameter Sets: (All)
    Aliases:
    Accepted values:

    Required: False
    Position: 1
    Default value: None
    Accept pipeline input: False
    Accept wildcard characters: False

.PARAMETER LogFullPath
    Display a date value like 9/15/2024 11:36:41.

    Type: SwitchParameter
    Parameter Sets: (All)
    Aliases:

    Required: False
    Position: 2
    Default value: None
    Accept pipeline input: False
    Accept wildcard characters: False

.EXAMPLE
    Write-Log 'Tracing script'
    12:13:00 [INFO]  Tracing script

.EXAMPLE
    Write-Log 'Tracing script' 'Debug' 'trace.log'
    12:21:41 [DEBUG]  Tracing script

.EXAMPLE        
    Get-WindowsVersion | ConvertTo-Json | Write-Log
    Dumps information about current system to the generated log.

.EXAMPLE    
    (&"C:\Program Files\7-Zip\7z.exe" l z.zip) | Out-String | Write-Log
    List files inside z.zip, print them to console and write to the log.
    
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
    This command is intended to let you see your verbose output and write the verbose messages to a log file. It will only work if the verbose pipeline is enabled, usually when your command is run with -Verbose. This function is designed to be used within your scripts and functions. You either have to hard code a file name or find some other way to define it in your function or control script. You could pass a value as a parameter or set it as a PSDefaultParameterValue.

    When the command is run with -Verbose you will see the verbose output and it will be saved to the specified log file.

.PARAMETER Append
    Append to the specified text file.

    Type: SwitchParameter
    Parameter Sets: (All)
    Aliases:

    Required: False
    Position: Named
    Default value: None
    Accept pipeline input: False
    Accept wildcard characters: False

.PARAMETER Encoding
    Specify a file encoding.

    Type: Encoding
    Parameter Sets: (All)
    Aliases:

    Required: False
    Position: Named
    Default value: None
    Accept pipeline input: False
    Accept wildcard characters: False

.PARAMETER Path
    The path for the output file.

    Type: String
    Parameter Sets: (All)
    Aliases:

    Required: True
    Position: 0
    Default value: None
    Accept pipeline input: False
    Accept wildcard characters: False

.PARAMETER Value
    The message to be displayed as a verbose message and saved to the file.

    Type: Object
    Parameter Sets: (All)
    Aliases:

    Required: True
    Position: Named
    Default value: None
    Accept pipeline input: True (ByValue)
    Accept wildcard characters: False

.EXAMPLE
    PS C:\> $VerbosePreference= "continue"
    PS C:\> $log = New-CustomFileName ".\VerboseLog_%time.txt"
    PS C:\> Write-Detail "This is a verbose log test" | Out-VerboseTee -Path $log
    PS C:\> Get-Content $log
    11/29/2024 08:21:31:0704 [PROCESS] This is a verbose log test
    PS C:\> $verbosePreference = "SilentlyContinue"
    Normally you would use this command inside a function or script, but you can run it from the console if you want to understand how it works.
#>
function Out-VerboseTee {
    [CmdletBinding()]
    [alias("log", "stdout")]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$Value,
        [Parameter(Position = 0, Mandatory)]
        [string]$Path,
        [System.Text.Encoding]$Encoding,
        [switch]$Append
    )
    Begin {
        #turn on verbose pipeline since if you are running this command you intend for it to be on
        $VerbosePreference = "continue"
    }
    Process {
        #only run if Verbose is turned on
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
    End {
        $VerbosePreference = "SilentlyContinue"
    }
}

<#
.SYNOPSIS
    Sends "pages" of objects to the pipeline.

.DESCRIPTION
    This function is designed to display groups or "pages" of objects to the PowerShell pipeline. It is modeled after the legacy More.com command-line utility. By default, the command will write objects out to the pipeline in groups of 50. You will be prompted after each grouping.

    Pressing M or Enter will get the next group. Pressing A will stop paging and display all of the remaining objects. Pressing N will display the next object. Press Q to stop writing anything else to the pipeline.

    Note that you may encounter an error message when quitting prematurely, especially on non-Windows platforms. You can ignore these errors.

.PARAMETER InputObject
    Specifies the objects to be sent to the pipeline.

    Type: Object[]
    Parameter Sets: (All)
    Aliases:

    Required: True
    Position: 1
    Default value: None
    Accept pipeline input: True (ByValue)
    Accept wildcard characters: False

.PARAMETER Count
    The number of objects to group as a page.

    Type: Int32
    Parameter Sets: (All)
    Aliases: i

    Required: False
    Position: 2
    Default value: 50
    Accept pipeline input: False
    Accept wildcard characters: False

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
    PS C:\> dir c:\work -file -Recurse | Out-More -ClearScreen | tee -Variable work
    List all files in C:\Work and page them to Out-More using the default count, but after clearing the screen first. The results are then piped to Tee-Object which saves them to a variable.
#>
function Out-More {
    [cmdletbinding()]
    [alias("more", "detailed")]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object[]]$InputObject,
        [ValidateRange(1, 1000)]
        [Alias("i")]
        [int]$Count = 50,
        [Alias("cls")]
        [Switch]$ClearScreen
    )

    Begin {
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

    Process {
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

        If ($Ready) {
            #pause
            Do {
                Write-Host "[M]ore [A]ll [N]ext [Q]uit " -ForegroundColor Green -NoNewline
                $r = Read-Host
                if ($r.Length -eq 0 -or $r -match "^m") {
                    #don't really do anything
                    $Asked = $True
                } else {
                    switch -Regex ($r) {
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
            } Until ($Asked)

            $Ready = $false
            $Asked = $false
        }
    }

    End {
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
    Retrieves help information for PowerShell commands or external applications.

.DESCRIPTION
    For built-in PowerShell commands (Cmdlet, Function, Alias), it uses the standard Get-Help function.
    For external applications, it automatically tries various help parameter variants
    (--help, -h, /?, etc.), eliminating the need to remember application-specific help syntax.

.PARAMETER command
    The name of the Cmdlet, Function, Alias, full or relative path to the application or app name from PATH enviromental variable.
    Use Get-EnvPath to retrieve full path for application from PATH variable.

    Type: String
    Parameter Sets: (All)
    Aliases:

    Required: True
    Position: 0
    Default value: None
    Accept pipeline input: True (ByValue)
    Accept wildcard characters: False

.PARAMETER arguments
    Arguments or sub-commands to pass to the command. If $command is PowerShell command (Cmdlet, Function, Alias), pass arguments for Get-Help command that will be used to retrieve help message or specific details about this $command.

    Type: String[]
    Parameter Sets: (All)
    Aliases:

    Required: False
    Position: 1
    Default value: None
    Accept pipeline input: False
    Accept wildcard characters: False

.INPUTS
    System.String

    You can pipe name or path to this function.

.OUTPUTS
    System.String

    Returns the help text for the command or application.

.EXAMPLE
    Get-HelpMessage Get-Process

    Description:
    Retrieves help for the built-in PowerShell command Get-Process.
    Equivalent to running Get-Help Get-Process.

.EXAMPLE
    Get-HelpMessage pip

    Description:
    Retrieves commands for the Python package manager.

.EXAMPLE
    Get-HelpMessage pip install

    Description:
    Retrieves help for the 'install' sub-command of Python package manager.

.EXAMPLE
    hlp taskkill.exe

    Description:
    Retrieves help information for the system32 taskkill.exe.exe application.

.EXAMPLE
    hlp ./git.exe

    Description:
    Retrieves help information for the git.exe in the current directory using 'hlp' alias.

.EXAMPLE
    hlp "C:\Program Files\Git\cmd\git.exe"

    Description:
    Retrieves help information for the git.exe using 'hlp' alias.

.EXAMPLE
    Get-EnvPath "cmder" | ForEach { Get-HelpMessage $_ }

    Description:
    Retrieves help information for all matching paths from PATH variable.

.EXAMPLE
    Get-HelpMessage Stop-HiddenScript -Parameter launcher

    Description:
    Retrieves detailed information about 'launcher' param.

.NOTES
    Requires Invoke-ExternalCommand for executing external applications and suppressing errors.
    https://github.com/choovick/ps-invoke-externalcommand

.LINK
    Get-Help

.LINK
    Get-Command

.LINK
    Invoke-ExternalCommand

.LINK
    Get-EnvPath
#>
function Get-HelpMessage {
    [cmdletbinding()]
    [alias('hlp', 'h')]

    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$command,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$arguments
    )

    begin {
        [string[]]$helpParams = @('--help', '-help', 'help', '-h', '--h', '-?', '/help', '/h', '/?')
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    }

    process {
        if ((Test-Path $command) -or
            (Get-Command $command -CommandType Application -ErrorAction Ignore)) {
            ForEach ($help in $helpParams) {
                $params = $arguments ? @($arguments, $help) : @($help)
                $cmd = Invoke-ExternalCommand $command $params `
                    -OutVarStdout output `
                    -HideStdout -HideStdErr -HideCommand `
                    -IgnoreExitCode -Return

                if (!$cmd.Code) {
                    return $cmd.StdOut
                }
            }
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
    Extracts and pretty-prints syntax for PowerShell commands (Cmdlet, Function, Alias) and external applications.

.PARAMETER command
    The name of the Cmdlet, Function, Alias, full or relative path to the application or app name from PATH enviromental variable.
    Use Get-EnvPath to retrieve full path for application from PATH variable.

    Type: String
    Parameter Sets: (All)
    Aliases: 

    Required: True
    Position: 0
    Default value: None
    Accept pipeline input: True (ByValue)
    Accept wildcard characters: False

.PARAMETER arguments
    Additional arguments to pass to external application for retrieving raw help message with syntax.

    Type: String[]
    Parameter Sets: (All)
    Aliases: 

    Required: False
    Position: 1
    Default value: None
    Accept pipeline input: False
    Accept wildcard characters: False

.INPUTS
    System.String

    You can pipe command name or path to this function.

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
    Get-HelpSyntax Get-Command

    Description:
    Displays all ParameterSets for Get-Command with formatted parameters.

.EXAMPLE
    Get-HelpSyntax ls

    Description:
    Resolves the 'ls' alias to Get-ChildItem and shows its syntax.

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
    [alias('?!', 'syntax', 'usage')]

    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$command,
        
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$arguments
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
    # Resolve alias
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
    Extracts and pretty-prints examples for PowerShell commands (Cmdlet, Function, Alias) and external applications.

.PARAMETER command
    The name of the Cmdlet, Function, Alias, full or relative path to the application or app name from PATH enviromental variable.
    Use Get-EnvPath to retrieve full path for application from PATH variable.

    Type: String
    Parameter Sets: (All)
    Aliases: 

    Required: True
    Position: 0
    Default value: None
    Accept pipeline input: True (ByValue)
    Accept wildcard characters: False

.PARAMETER arguments
    Additional arguments to pass to external application for retrieving raw help message with examples.

    Type: String[]
    Parameter Sets: (All)
    Aliases: 

    Required: False
    Position: 1
    Default value: None
    Accept pipeline input: False
    Accept wildcard characters: False

.INPUTS
    System.String

    You can pipe command name or path to this function.

.OUTPUTS
    System.String

    Returns extracted examples.

.EXAMPLE
    Get-HelpExample Get-Command

    Description:
    Displays all examples for Get-Command.

.EXAMPLE
    Get-HelpExample ls

    Description:
    Resolves the 'ls' alias to Get-ChildItem and shows its examples.

.EXAMPLE
    Get-HelpExample gh

    Description:
    Extracts syntax for the gh.exe (GitHub) using 'usage' alias.

.EXAMPLE
    Get-HelpExample gh search

    Description:
    Extracts example for the 'search' sub-command of GitHub command.

.EXAMPLE
    Get-HelpExample "C:\Windows\system32\taskkill.exe"

    Description:
    Extracts syntax for the taskkill.exe using 'usage' alias.

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
        $command,  
        
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$arguments
    )

    $help = Get-HelpMessage $command $arguments
    
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
        return
    }

    if ($help -match '(?msix) Examples? (?: :|\r?\n) (.+?) (?: \r?\n \r?\n [A-Z] | \z)') {
        $matches[1].Trim() -split "`n" | ForEach {
            if ($_) {
                $_
            }
        }
    }
}

<#
.SYNOPSIS
    Retrieves error information based on the code.

.DESCRIPTION
    This function uses the certutil command to obtain error information based on the provided code.

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
    Outputs the description: "Exception handlers will not be invoked, the process will be terminated immediately."

.EXAMPLE
    Get-Error -code 0xc0000602 -UI
    Displays a window "An error occurred" with its number and description.
#>
function Get-Error {
    [cmdletbinding()]
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
    Displays path from PATH enviromental variable.

.DESCRIPTION
    Returns any ocurrence of the searched filename in the folders contained in path variable.
    Gives more flexibility in selecting what we wan't to execute instead of just typing
    the executables name to the CLI or our script and relying on the Windows firstmatch principle.

.PARAMETER filename
    Name of the executable file.

    Type: String
    Parameter Sets: (All)
    Aliases:

    Required: True
    Position: 0
    Default value: None
    Accept pipeline input: True (ByValue)
    Accept wildcard characters: False

.INPUTS
    System.String
    You can pipe a filename string to this function.

.OUTPUTS
    System.String
    Returns full path(s) to the executable file(s) found in PATH directories. Each path will be on its own line.

.EXAMPLE
    Get-EnvPath -filename notepad.exe
    C:\Windows\system32\notepad.exe <---- first  match
    C:\Windows\notepad.exe          <---- second match

.EXAMPLE
    You can omit ".exe" in the name. It will be added at the end of the request:
    Get-EnvPath -filename conemu64
    C:\Users\ToYu\cmder\vendor\conemu-maximus5\conemu64.exe


.EXAMPLE
    Get-EnvPath "conemu" | ForEach { Get-HelpMessage $_ }

    Description:
    Retrieves help information for all ConEmu paths found in PATH variable.
#>
function Get-EnvPath {
    [cmdletbinding()]
    [alias("env", "envget", "path")]

    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$filename
    )

    $env:Path -split ";" | ForEach {
        # Search for files matching the name with any extension
        Get-ChildItem -Path $_ -Filter "$filename*" -File -ErrorAction SilentlyContinue |
            Where { $filename -like "$($_.BaseName)*" }
    } | Select -ExpandProperty FullName
}

<#
.SYNOPSIS
    Counts the total number of lines in files within a specified path.

.DESCRIPTION
    Recursively searches for files by filter in the specified directory and counts the total lines across all files.
    Displays individual file line counts and a total summary.

.PARAMETER Path
    The root path to search for. Defaults to current directory.
    
    Type: String
    Parameter Sets: (All)
    Aliases:

    Required: True
    Position: 0
    Default value: None
    Accept pipeline input: True (ByValue)
    Accept wildcard characters: True
    
.PARAMETER Filter
    File filter pattern. Defaults to *.ahk.
    
    Type: String
    Parameter Sets: (All)
    Aliases:

    Required: False
    Position: 1
    Default value: None
    Accept pipeline input: False
    Accept wildcard characters: False

.EXAMPLE
    Get-LineCount -Path "C:\Scripts"

.EXAMPLE
    Get-LineCount -Path "Build.ahk" -Recurse

.OUTPUTS
    PSCustomObject with properties: FullName, LineCount
#>
function Get-LineCount {    
    [CmdletBinding()]
    [alias('lines')]
    
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
    }
    
    process {
        $files = Get-ChildItem `
            -Path $Path -Filter $Filter `
            -ErrorAction SilentlyContinue `
            -Recurse
        
        if (-not $files) {
            Write-Warning "No $Filter files found in `"$Path`""
            return
        }
        
        foreach ($file in $files) {
            $content = Get-Content -Path $file.FullName -ErrorAction SilentlyContinue
            
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
    Stops running scripts by searching for hidden windows with specified script paths in the title.

    You can specify full or relative paths to the scripts or just filenames to find all matches using Everything search tool and terminate them.

.PARAMETER names
    Specifies the paths/names of the scripts to stop.

    Type: String[]
    Parameter Sets: (All)
    Aliases:

    Required: True
    Position: 0
    Default value: None
    Accept pipeline input: True (ByValue)
    Accept wildcard characters: False

.PARAMETER launcher
    Specifies the owner/launcher of the script (e.g., "autohotkey", "python").
    This is used to filter processes by name pattern. If empty or missing, function terminates everything that was found by $names.

    Type: String
    Parameter Sets: (All)
    Aliases:

    Required: False
    Position: 1
    Default value: None
    Accept pipeline input: False
    Accept wildcard characters: False

.PARAMETER force
    Stops the specified/found scripts without prompting for confirmation.

    Type: SwitchParameter
    Parameter Sets: (All)
    Aliases:

    Required: False
    Position: Named
    Default value: False
    Accept pipeline input: False
    Accept wildcard characters: False

.PARAMETER confirm
    Prompts for confirmation before stopping each specified/found script.

    Type: SwitchParameter
    Parameter Sets: (All)
    Aliases:

    Required: False
    Position: Named
    Default value: False
    Accept pipeline input: False
    Accept wildcard characters: False

.INPUTS
    System.String[]

    You can pipe script names to this function.

.OUTPUTS
    None

.EXAMPLE
    Stop-HiddenScript "C:\Script1.ahk", "C:\Script2.py"

    Stops multiple scripts at once.

.EXAMPLE
    Stop-Script "Script1.ahk", "Script2.py" -confirm

    Searches for scripts and prompts for confirmation before terminating each found script.

.EXAMPLE
    Stop-HiddenScript -names "Script1.py", "Script2.py" -launcher "python" -force

    Searches for Python scripts and terminates them if they are launched using "python" process.

.NOTES
    Requirements:
    - es.exe (Everything search tool) for search method.
    - Administrative privileges may be required for some processes

    See Stop-Script for termination without search tool.

.LINK
    tasklist.exe

.LINK
    taskkill.exe
#>
function Stop-HiddenScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string[]]$names,

        [Parameter()]
        [AllowEmptyString()]
        [string]$launcher = "",

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

                $response = Read-Host "[Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is `"Y`")"

                :AnalyzeResponse switch ($response) {
                    'A' { $confirm = $false; break AskConfirm }
                    'Y' { break AskConfirm }
                    'N' { continue StopScripts }
                    'L' { return $false }
                    'S' { exit 1 }

                    default {
                        Write-Host "Y - Terminate current process.`nA - Terminate all processes without prompting`nN - Skip current process.`nL - Skip all remaining processes.`nS - Pause current operation and return to the command prompt."
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
    Stops running scripts by searching for processes associated with the specified script names (processes with files in command line).

    The function tries multiple methods sequentially (including Stop-HiddenScript function) and returns after the first successful termination method.

.PARAMETER names
    Specifies the names of the scripts to stop.

    Type: String[]
    Parameter Sets: (All)
    Aliases:

    Required: True
    Position: 0
    Default value: None
    Accept pipeline input: True (ByValue)
    Accept wildcard characters: True

.PARAMETER launcher
    Specifies the owner/launcher of the script (e.g., "autohotkey", "python").
    This is used to filter processes by name pattern. Cannot be empty.

    Type: String
    Parameter Sets: (All)
    Aliases:

    Required: False
    Position: 1
    Default value: autohotkey
    Accept pipeline input: False
    Accept wildcard characters: True

.PARAMETER force
    Stops the specified scripts without prompting for confirmation.

    Type: SwitchParameter
    Parameter Sets: (All)
    Aliases:

    Required: False
    Position: Named
    Default value: False
    Accept pipeline input: False
    Accept wildcard characters: False

.PARAMETER confirm
    Prompts for confirmation before stopping each script.

    Type: SwitchParameter
    Parameter Sets: (All)
    Aliases:

    Required: False
    Position: Named
    Default value: False
    Accept pipeline input: False
    Accept wildcard characters: False

.INPUTS
    System.String[]

    You can pipe script names to this function.

.OUTPUTS
    None

    The function outputs a formatted table of terminated processes showing Id and
    ProcessName, along with status messages indicating success or failure.

.NOTES
    Requirements:
    - es.exe (Everything search tool) for additional search method.
    - Administrative privileges may be required for some processes.

    See Stop-HiddenScript for multiple scripts termination without specifying launcher.

.EXAMPLE
    Stop-Script "Script1", "Script2"

    Stops multiple AutoHotkey scripts at once.

.EXAMPLE
    Stop-Script "Script1", "Script2" -confirm

    Prompts for confirmation before terminating each found script.

.EXAMPLE
    kills -names "Script1.py", "Script2.py" -launcher "python" -force

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
    [alias('kills', 'stop')]

    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
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

<#
.SYNOPSIS
    Retrieves Windows system restore points in a simplified format.

.DESCRIPTION
    Use 'checkpoints' alias to see all system restore points in the user-friendly format. 
    Returns restore points sorted by ID in descending order 
    (newest first) with Description, ID, and Date columns.     

.PARAMETER RestorePoint
    The sequence number of the restore point.
    
    Type: UInt32[]
    Parameter Sets: (All)
    Aliases:

    Required: False
    Position: 1
    Default value: None
    Accept pipeline input: True
    Accept wildcard characters: False

.EXAMPLE
    checkpoints
    
    Lists all restore points, sorted by newest first.

.EXAMPLE
    checkpoints 12, 13
    
    Returns information about restore point with index 12 and 13.

.EXAMPLE
    checkpoints | Where-Object {$_.Description -like '*Update*'}
    
    Filters restore points containing "Update" in description.

.EXAMPLE
    checkpoints | Select -First 5
    
    Shows only the 5 most recent restore points.

.OUTPUTS
    System.Object[]
    
    Returns an array of custom objects:    
    @{
        [string]   Description  - The description of the restore point
        [int32]    ID           - The sequence number of the restore point
        [DateTime] Date         - The creation date and time of the restore point
    }
          
    Objects are sorted by ID in descending order (newest first).

.NOTES
    SequenceNumber is displayed as "ID" for better readability.
    CreationTime is converted from WMI format to readable DateTime.
    Results are sorted by ID in descending order (newest to oldest).

.LINK
    Get-ComputerRestorePoint
#>
function Get-Checkpoint {
    [CmdletBinding()]
    
    [Parameter(Mandatory = $false, ValueFromPipeline)]
    param([uint32[]]$RestorePoint)
    
    if ($RestorePoint) {
        $checkpoints = Get-ComputerRestorePoint $RestorePoint
    } else {
        Write-Host 'Getting available checkpoints...'
        $checkpoints = Get-ComputerRestorePoint
    }

    $checkpoints | Select Description, `
    @{
        Name = "ID";
        Expression = { $_.SequenceNumber }
    }, `
    @{
        Name = "Date";
        Expression = {
            [System.Management.ManagementDateTimeConverter]::ToDateTime($_.creationtime)
        }
    } | Sort ID -Descending
}

Set-Alias   checkpoint   Checkpoint-Computer
Set-Alias   checkpoints  Get-Checkpoint

<#
.SYNOPSIS
    Restores Windows system to a previous restore point.

.DESCRIPTION
    The restore function initiates system restore to a specified restore point.
    If no restore point is specified, displays an interactive selection window.
    System will restart after restore is initiated.

.PARAMETER RestorePoint
    The sequence number of the restore point to restore to.
    If not specified, displays an interactive selection window.

    Type: UInt32
    Parameter Sets: (All)
    Aliases:

    Required: True
    Position: 1
    Default value: None
    Accept pipeline input: True
    Accept wildcard characters: False

.EXAMPLE
    restore 27
    
    Restores system to restore point with sequence number 27.

.EXAMPLE
    restore
    
    Opens interactive window to select a restore point, then restores to the selected point.

.NOTES
    Requires running PowerShell as Administrator and Out-ConsoleGridView function.
    System will restart automatically after initiating restore.
    Ensure all work is saved before running this function.

.LINK
    Restore-Computer
    Get-ComputerRestorePoint
    Out-ConsoleGridView
#>
function restore {
    [CmdletBinding()]
    
    [Parameter(Mandatory = $true, ValueFromPipeline)]
    param([uint32]$RestorePoint) 
    
    if (!$RestorePoint) {
        $selection = checkpoints | Out-ConsoleGridView -title 'Restore points' -output single
        $RestorePoint = $selection.ID
        
        if (!$RestorePoint) {
            Write-Host 'Cancel restore' -f DarkGray
            return
        }
    }
    
    if ($RestorePoint) {
        Write-Host 'Init restore, please wait...'
        checkpoints $RestorePoint
        
        Restore-Computer $RestorePoint
    } else {
        Write-Error 'Restore point not found'
    }
}

<#
.SYNOPSIS
    Resizes the shadow copy storage space for system restore points.

.DESCRIPTION
    The Resize-Checkpoint function resizes the maximum size of shadow copy storage 
    association on current drive. This operation may cause existing shadow copies (restore points) to be deleted if the new size is smaller than currently used space.

.PARAMETER size
    Maximum size for shadow copy storage in
    percentage (1-99%) of the current drive or in bytes (320MB or more) with the following suffixes: 
    KB, MB, GB, TB, PB and EB. Also, B, K, M, G, T, P, and E are acceptable suffixes.  
    Use 'UNBOUNDED' for unlimited storage (not supported in this function).
    
    Resizing the storage association may cause shadow 
    copies to disappear.  As certain shadow copies are deleted, the shadow copy storage 
    space will then shrink.

.EXAMPLE
    Resize-Checkpoint 10%
    
    Sets shadow copy storage to 10% of current drive capacity.

.EXAMPLE
    Resize-Checkpoint 5GB
    
    Sets shadow copy storage to 5GB of current drive capacity.
    May delete existing restore points if current usage exceeds new limit.

.NOTES
    Requires running PowerShell as Administrator.
    Resizing storage may cause shadow copies to disappear.
    As shadow copies are deleted, storage space will shrink accordingly.

.LINK
    vssadmin
#>
function Resize-Checkpoint($size) {    
    $drive = $pwd.Drive.Name + ':'
    vssadmin.exe resize shadowstorage /for=$drive /on=$drive /maxsize=$size
}

<#
.SYNOPSIS
    Deletes Windows system restore points.

.DESCRIPTION
    Deletes specified Windows restore points by their sequence numbers.
    Can accept numbers via parameter, pipeline, or display an interactive selection window.

.PARAMETER SequenceNumber
    The sequence number (ID) of the restore point to delete.

    Type: Int32[]
    Parameter Sets: (All)
    Aliases: ID

    Required: False
    Position: 0
    Default value: False
    Accept pipeline input: True (ByPropertyName)
    Accept wildcard characters: False
    
.INPUTS
    System.Int32
    System.Management.ManagementObject#root\default\SystemRestore
    
    You can pipe restore point numbers or Get-ComputerRestorePoint objects.

.OUTPUTS
    None   

.EXAMPLE
    Remove-Checkpoint 27
    
    Deletes restore point with sequence number 27.

.EXAMPLE
    Remove-Checkpoint 27, 28, 30 -confirm
    
    Deletes multiple restore points after confirmation.

.EXAMPLE
    checkpoints | Where-Object {$_.Description -like '*Update*'} | Remove-Checkpoint
    
    Deletes all restore points containing "Update" in description.

.EXAMPLE
    Remove-Checkpoint
    
    Opens interactive window to select restore points.

.NOTES
    Requires running PowerShell as Administrator.
    Uses SRRemoveRestorePoint function from Srclient.dll:
    https://learn.microsoft.com/en-us/windows/win32/api/srrestoreptapi/nf-srrestoreptapi-srremoverestorepoint

.LINK
    Get-ComputerRestorePoint
    Checkpoint-Computer    
#>
function Remove-Checkpoint {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [parameter(ValueFromPipelineByPropertyName)]
        [Alias('ID')]
        $SequenceNumber
    )
    
    begin {
        $fullName = "SystemRestore.DeleteRestorePoint"
        # check if the type is already loaded
        $isLoaded = ([AppDomain]::CurrentDomain.GetAssemblies() | 
            ForEach {$_.GetTypes()} | 
            Where {$_.FullName -eq $fullName}
        ) -ne $null
        
        if (!$isLoaded) {
            $SRClient = Add-Type -MemberDefinition @"
                [DllImport("Srclient.dll")]
                public static extern int SRRemoveRestorePoint(int index);
"@ -Name DeleteRestorePoint -Namespace SystemRestore -PassThru
        }
    }
    
    process {
        if (!$SequenceNumber) {
            $SequenceNumber = checkpoints | 
                Out-ConsoleGridView -title 'Restore points' -output multiple |
                ForEach {
                    $_.ID
                }
        }

        $SequenceNumber | ForEach {
            $id = $_
            if ($PSCmdlet.ShouldProcess($id, 'Deleting restore point')) {
                $result = [SystemRestore.DeleteRestorePoint]::SRRemoveRestorePoint($id)
                
                switch ($result) {
                    0 {
                        Write-Host 'Restore point ' -f DarkGray -n
                        Write-Host $id       -f Blue     -n
                        Write-Host ' is '    -f DarkGray -n
                        Write-Host 'deleted' -f Green
                    }
                    2 {
                        Write-Warning "Invalid restore point number: $id"
                    }
                    13 {
                        Write-Warning "Invalid data for restore point"
                    }
                    default {
                        Write-Warning "Failed to delete restore point $id. Error code: $result"
                    }
                }
            }
        }
    }
}