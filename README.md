This collection of functions is designed to simplify the completion of basic tasks without relying on slow Windows UI. It can help you to learn PowerShell: retrieve information about commands and CLI utilities using the [Get-Help*](/SystemEssentials/README.md#help--documentation) set of cmdlets. By studying the source code, you'll also gain a better understanding of what PowerShell is truly capable of. And the [Write-*](/SystemEssentials/README.md#logging--output) cmdlets will help you write scripts with greater ease.

# Contents

#### Modules

- [SystemEssentials](/SystemEssentials/README.md) - Useful tools for learning and scripting on PowerShell.

- [SystemRestore](/SystemRestore/README.md) - Backup and restore the system from terminal.

- [Environment.Path](/Environment.Path/README.md) - Manipulate and retrieve `Path` environment variable.

#### Scripts

- [Rename-UserProfile](https://github.com/JoyHak/UserProfileRename) - Rename user account and home folder.

# Installation

TLDR: Clone this repository to `$HOME\Documents\PowerShell\Modules`. Add `Import-Module <ModuleName>` in your profile.

Run the following commands in PowerShell:

```powershell
$InstallPath = $env:PSModulePath -split ([IO.Path]::PathSeparator) | select -first 1
git clone 'https://github.com/JoyHak/PowerShell.git' $InstallPath
```

or

```bash
gh repo clone JoyHak/PowerShell $InstallPath
```

Add imports to your profile. Run `notepad $profile` and add this at the top:

```powershell
Install-Module Microsoft.PowerShell.ConsoleGuiTools # for SystemRestore only, you can remove it
Import-Module SystemRestore
Import-Module SystemEssentials
Import-Module Environment.Path

# optional
Remove-Alias ? -Force
Set-Alias  ?       Get-HelpMessage
Set-Alias  error   Get-Error
Set-Alias  grid    Out-ConsoleGridView
```

## Verification

```powershell
Get-Command -module `
    SystemEssentials, SystemRestore, Environment.Path `
    -command Function, Alias
```

## Update

To update a manually installed module, repeat the installation steps, or run:

```powershell
$InstallPath = $env:PSModulePath -split ([IO.Path]::PathSeparator) | select -first 1
git -C $InstallPath pull
```

or

```powershell
Set-Location $InstallPath
gh repo sync
```

## Uninstall

```powershell
Uninstall-Module SystemEssentials, SystemRestore, Environment.Path, Microsoft.PowerShell.ConsoleGuiTools
```

or

```powershell
Get-InstalledModule `
    SystemEssentials, SystemRestore, Environment.Path, Microsoft.PowerShell.ConsoleGuiTools | 
    select -expand InstalledLocation | 
    Remove-Item -force -recurse
```


