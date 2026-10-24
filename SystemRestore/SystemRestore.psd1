@{
RootModule              =  'SystemRestore.psm1'
ModuleVersion           =  '1.0.0'
CompatiblePSEditions    =  @('Desktop', 'Core')
Author                  =  'Rafaello'
CompanyName             =  'ToYu studio'
Copyright               =  'GNU General Public License v3.0'
Description             =  'Backup and restore the system from terminal.'
HelpInfoURI             = 'https://github.com/JoyHak/PowerShell/tree/main/SystemRestore#readme'
PrivateData = @{
    PSData = @{
        Tags = @('checkpoint', 'restore', 'backup', 'restorepoint')
        LicenseUri   = 'https://github.com/JoyHak/PowerShell/blob/main/LICENSE'
        ProjectUri   = 'https://github.com/JoyHak/PowerShell/tree/main/SystemRestore'
        ReleaseNotes = 'https://github.com/JoyHak/PowerShell/releases'
        IconUri      = 'https://raw.githubusercontent.com/JoyHak/PowerShell/refs/heads/main/Icons/SystemRestore.ico'
    } 
}
PowerShellVersion       =  '7.5'
RequiredModules         =  @('Microsoft.PowerShell.ConsoleGuiTools')
}

