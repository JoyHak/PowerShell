<#
.SYNOPSIS
    Retrieves Windows system restore points in a simplified format.

.DESCRIPTION
    Use 'checkpoints' Alias to see all system restore points in the user-friendly format.
    Returns restore points sorted by ID in descending order
    (newest first) with Description, ID, and Date columns.

.PARAMETER RestorePoint
    The sequence number of the restore point.

.EXAMPLE
    checkpoints

    Description:
    Lists all restore points, sorted by newest first.

.EXAMPLE
    checkpoints 12, 13

    Description:
    Returns information about restore point with index 12 and 13.

.EXAMPLE
    checkpoints | Where-Object {$_.Description -like '*Update*'}

    Description:
    Filters restore points containing "Update" in description.

.EXAMPLE
    checkpoints | Select -First 5

    Description:
    Shows only the 5 most recent restore points.

.OUTPUTS
    System.Object[]

    Returns available restore points:
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

.EXAMPLE
    restore 27

    Description:
    Restores system to restore point with sequence number 27.

.EXAMPLE
    restore

    Description:
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
    association on current drive. This operation may cause existing shadow copies 
    (restore points) to be deleted if the new size is smaller than currently used space.

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

    Description:
    Sets shadow copy storage to 10% of current drive capacity.

.EXAMPLE
    Resize-Checkpoint 5GB

    Description:
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

.INPUTS
    System.Int32
    System.Management.ManagementObject#root\default\SystemRestore

    You can pipe restore point numbers or Get-ComputerRestorePoint objects.

.OUTPUTS
    None

.EXAMPLE
    Remove-Checkpoint

    Description:
    Opens interactive window to select restore points.

.EXAMPLE
    Remove-Checkpoint 27

    Description:
    Removes restore point with sequence number 27.

.EXAMPLE
    Remove-Checkpoint 27, 28, 30 -confirm

    Description:
    Removes multiple restore points after confirmation.

.EXAMPLE
    checkpoints | Where-Object {$_.Description -like '*Update*'} | Remove-Checkpoint

    Description:
    Removes all restore points containing "Update" in description.


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