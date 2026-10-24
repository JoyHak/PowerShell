@{
RootModule              =  'SystemEssentials.psm1'
ModuleVersion           =  '1.0.0'
CompatiblePSEditions    =  @('Desktop', 'Core')
GUID                    =  'f8deaba5-5c23-43aa-a59f-f508e7369a30'
Author                  =  'Rafaello'
CompanyName             =  'ToYu studio'
Copyright               =  'GNU General Public License v3.0'
Description             =  'A collection of functions for simplified but effective interaction with Windows, 
allowing the average user to use the terminal.

You can contribute and get examples here: https://github.com/JoyHak
'
HelpInfoURI = 'https://github.com/JoyHak'
PrivateData = @{
    PSData = @{
        Tags = 'winver', 'stop', 'script', 'scripts', 'help', 'more', 'table', 'interactive', 'selection', 'checkpoint'

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/AnderssonPeter/PowerType/blob/main/LICENSE.md'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/AnderssonPeter/PowerType/'

        # A URL to an icon representing this module.
        IconUri = 'https://raw.githubusercontent.com/AnderssonPeter/PowerType/main/Icon.svg'

        ReleaseNotes = '## What''s Changed
* added support for docker and more commads for git by @Juanma7882 in https://github.com/AnderssonPeter/PowerType/pull/41
* Upgraded to latest nuget packages
* Fixed bug in git stash pop suggestion (#39)

## New Contributors
* @Juanma7882 made their first contribution in https://github.com/AnderssonPeter/PowerType/pull/41

**Full Changelog**: https://github.com/AnderssonPeter/PowerType/compare/0.1.0...0.1.1'

        # Prerelease = ''

    } 
}
PowerShellVersion       =  '7.5'
RequiredModules         =  @('Microsoft.PowerShell.ConsoleGuiTools', 'ExternalCommand')
}

