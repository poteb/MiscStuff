# Registers the "NightlyBackup" scheduled task (daily 02:00, runs as current user).
# Re-run to update. Remove with: Unregister-ScheduledTask NightlyBackup -Confirm:$false
param([string]$At = '02:00')

$script = Join-Path $PSScriptRoot 'Backup.ps1'
$action = New-ScheduledTaskAction -Execute 'powershell.exe' `
    -Argument "-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$script`""
$trigger  = New-ScheduledTaskTrigger -Daily -At $At
$settings = New-ScheduledTaskSettingsSet -WakeToRun -StartWhenAvailable -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 8)

Register-ScheduledTask -TaskName 'NightlyBackup' -Action $action -Trigger $trigger -Settings $settings `
    -Description "Robocopy folders.txt -> E:\Backup (mirror), F:\Backup (additive). $script" -Force
