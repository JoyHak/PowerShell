<a href="https://www.powershellgallery.com/packages/SystemRestore">
	<img src="https://img.shields.io/powershellgallery/v/SystemRestore?logo=termius&label=PsGallery&color=8293e6" alt="PsGallery">
</a>
<a href="https://github.com/JoyHak/PowerShell#installation">
	<img src="https://img.shields.io/powershellgallery/dt/SystemRestore?style=flat&logo=AB%20download%20manager&logoColor=8293e6&color=8293e6" alt="Installation">
</a>

# SystemRestore

Backup and restore the system from terminal.

## Table of Contents

- [Get-Checkpoint](#get-checkpoint)
- [Checkpoint-Computer](#checkpoint-computer)
- [restore](#restore)
- [Resize-Checkpoint](#resize-checkpoint)
- [Remove-Checkpoint](#remove-checkpoint)
- [Aliases](#aliases)

> [!WARNING]
> **Administrator privileges required** for all restore point management functions.
> But you can safely call `checkpoints` and `restore` without them.

---

### Get-Checkpoint

*Alias: `checkpoints`*

Retrieves Windows system restore points in a user-friendly format. Sorted by ID descending (newest first).

| Parameter      | Required | Type     | Description                                                     |
| -------------- | -------- | -------- | --------------------------------------------------------------- |
| `RestorePoint` | No       | uint32[] | Sequence number(s) of restore point(s) (accepts pipeline input) |

Returns available restore points (checkpoints):

| Property    | Type     | Description                      |
| ----------- | -------- | -------------------------------- |
| Description | string   | Restore point description        |
| ID          | int32    | Sequence number (SequenceNumber) |
| Date        | DateTime | Creation date and time           |

<details>
  <summary>Examples</summary>

```powershell
# All restore points (newest first)
checkpoints

# Specific points by ID
checkpoints 12, 13

# Filter by description
checkpoints | Where-Object {$_.Description -like '*Update*'}

# Last 5 points
checkpoints | Select -First 5
```

</details>

### Checkpoint-Computer

*Alias: `checkpoint`*

[Creates a system restore point on the local computer.](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/checkpoint-computer?view=powershell-5.1) (PowerShell built-in).

| Parameter          | Required | Type   | Description                             |
| ------------------ | -------- | ------ | --------------------------------------- |
| `Description`      | Yes      | string | Descriptive name for the restore point. |
| `RestorePointType` | No       | string | The type of restore point.              |

<details>
  <summary>Examples</summary>

This command creates a system restore point called Install MyApp and uses the default restore point type:

```powershell
Checkpoint-Computer -Description "Install MyApp"
```

Create a system restore point:

```powershell
Checkpoint-Computer -Description "ChangeNetSettings" -RestorePointType MODIFY_SETTINGS
```

</details>

### restore

Restores the system to a previous restore point. If no point is specified, show an interactive TUI.

| Parameter      | Required | Type   | Description                                                              |
| -------------- | -------- | ------ | ------------------------------------------------------------------------ |
| `RestorePoint` | No       | uint32 | Sequence number of the restore point. If omitted — interactive selection |

<details>
  <summary>Examples</summary>

Call `checkpoints` or `restore` without parameters to see all available checkpoints with IDs.

```powershell
# Restore to a specific point
restore 27

# Interactive selection via Out-ConsoleGridView
restore
```

</details>

### Resize-Checkpoint

Resizes the maximum shadow copy storage space for system restore points.

| Parameter | Required | Type   | Description                                                                                                                          |
| --------- | -------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------ |
| `size`    | Yes      | string | Max size: percentage (`10%`) or bytes with suffix (`KB`, `MB`, `GB`, `TB`, `PB`, `EB`). Shorthand: `B`, `K`, `M`, `G`, `T`, `P`, `E` |

<details>
  <summary>Examples</summary>

```powershell
# 10% of the drive
Resize-Checkpoint 10%

# 5 GB (may delete older points if limit is exceeded)
Resize-Checkpoint 5GB
```

</details>

### Remove-Checkpoint

Deletes specified restore points by their sequence numbers. If no point is specified, opens an interactive selection TUI.

| Parameter        | Required | Type   | Description                                                                                 |
| ---------------- | -------- | ------ | ------------------------------------------------------------------------------------------- |
| `SequenceNumber` | No       | object | Sequence number(s) of restore point(s) to delete (accepts pipeline input and `ID` property) |

<details>
  <summary>Examples</summary>

```powershell
# Interactive selection via Out-ConsoleGridView
Remove-Checkpoint

# Delete a specific point
Remove-Checkpoint 27

# Delete multiple points with confirmation
Remove-Checkpoint 27, 28, 30 -confirm

# Delete by filter
checkpoints | Where-Object {$_.Description -like '*Update*'} | Remove-Checkpoint
```

</details>

## Aliases

| Alias         | Function              | Description                    |
| ------------- | --------------------- | ------------------------------ |
| `checkpoint`  | `Checkpoint-Computer` | Create a restore point         |
| `checkpoints` | `Get-Checkpoint`      | List restore points            |
| `restore`     |                       | Restore selected restore point |

---

## Dependencies

| Module                                 | Purpose                                           |
| -------------------------------------- | ------------------------------------------------- |
| `Microsoft.PowerShell.ConsoleGuiTools` | Interactive selection TUI (`Out-ConsoleGridView`) |

---

## License

[GNU General Public License v3.0](../LICENSE)
