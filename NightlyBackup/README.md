# NightlyBackup

Robocopies the folders listed in `folders.txt` every night at 02:00:

- `E:\Backup\<drive>\<path>`: exact mirror (`/MIR`). Files you delete on the source are deleted here too.
- `F:\Backup\<drive>\<path>`: additive (`/E`). Files you delete on the source are kept here.

Logs go to `E:\Backup\_logs` and `F:\Backup\_logs` and are kept for 60 days.

## Usage

- **Change what is backed up:** edit `folders.txt`, one path per line. No re-install needed.
  - A plain path is backed up to both E and F.
  - Add `| E` to back it up to E only (mirror), or `| F` for F only (additive). Example: `D:\Downloads | E`- **Install or update the task:** run `.\Install-Task.ps1`. Use `-At 03:30` to change the time.
- **Run it now:** `Start-ScheduledTask NightlyBackup`
- **Remove the task:** `Unregister-ScheduledTask NightlyBackup -Confirm:$false`
- **Run even when logged off** (needs an admin PowerShell):
  `Set-ScheduledTask NightlyBackup -Principal (New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType S4U)`
