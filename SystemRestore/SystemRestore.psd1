@{
RootModule              =  'SystemRestore.psm1'
ModuleVersion           =  '1.0.0'
CompatiblePSEditions    =  @('Desktop', 'Core')
Author                  =  'Rafaello'
CompanyName             =  'ToYu studio'
Copyright               =  'GNU General Public License v3.0'
Description             =  'Backup and restore the system from terminal.'
HelpInfoURI = 'https://github.com/JoyHak'
PrivateData = @{
    PSData = @{
        Tags = @('checkpoint', 'restore', 'backup', 'restorepoint')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/AnderssonPeter/PowerType/blob/main/LICENSE.md'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/AnderssonPeter/PowerType/'

        # A URL to an icon representing this module.
        IconUri = 'https://raw.githubusercontent.com/AnderssonPeter/PowerType/main/Icon.svg'
    } 
}
PowerShellVersion       =  '7.5'
RequiredModules         =  @('Microsoft.PowerShell.ConsoleGuiTools')
}

