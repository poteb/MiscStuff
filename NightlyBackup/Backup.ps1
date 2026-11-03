<#
.SYNOPSIS
  Nightly backup of folders listed in folders.txt (all targets, or only those after "|").
    E:\Backup  -> exact mirror (/MIR): deletions on source are deleted here too.
    F:\Backup  -> additive (/E): nothing is ever deleted; deleted files survive here.
  Destination keeps the source path, e.g. D:\Photos\2024 -> E:\Backup\D\Photos\2024.
  Exit code 0 = OK, 1 = at least one copy failed (shows as failure in Task Scheduler).
#>
param(
    [string]$FolderList = (Join-Path $PSScriptRoot 'folders.txt'),
    [int]$KeepLogDays = 60
)

$targets = [ordered]@{
    E = @{ Root = 'E:\Backup'; Mode = '/MIR' }
    F = @{ Root = 'F:\Backup'; Mode = '/E'   }
}

# Line format:  <path> [| <targets>]   e.g.  "D:\Photos"  or  "D:\Cache | E"
# No "|" part = all targets.
$failed  = $false
$entries = Get-Content $FolderList -ErrorAction Stop |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -and -not $_.StartsWith('#') } |
    ForEach-Object {
        $path, $spec = $_ -split '\|', 2
        $keys = if ($spec -and $spec.Trim()) { $spec -split '[,\s]+' | Where-Object { $_ } | ForEach-Object { $_.ToUpper() } }
                else       { @($targets.Keys) }
        $bad = $keys | Where-Object { -not $targets.Contains($_) }
        if ($bad) { Write-Warning "Unknown target '$($bad -join ',')' in line: $_"; $failed = $true }
        [pscustomobject]@{ Path = $path.Trim(); Targets = @($keys | Where-Object { $targets.Contains($_) }) }
    }

if (-not $entries) { Write-Output "No folders in $FolderList - nothing to do."; exit 0 }

$stamp = Get-Date -Format 'yyyy-MM-dd_HHmm'

foreach ($key in $targets.Keys) {
    $t       = $targets[$key]
    $folders = @($entries | Where-Object { $_.Targets -contains $key } | ForEach-Object Path)
    if (-not $folders) { continue }

    $drive = Split-Path $t.Root -Qualifier
    if (-not (Test-Path "$drive\")) { Write-Warning "$drive not available - skipping."; $failed = $true; continue }

    $logDir = Join-Path $t.Root '_logs'
    New-Item -ItemType Directory -Force $logDir | Out-Null
    $log = Join-Path $logDir "$stamp.log"

    foreach ($src in $folders) {
        if (-not (Test-Path -LiteralPath $src -PathType Container)) {
            "!! Source missing, skipped: $src" | Add-Content $log
            $failed = $true; continue
        }
        # D:\Photos\2024 -> <root>\D\Photos\2024
        $full = (Resolve-Path -LiteralPath $src).ProviderPath.TrimEnd('\')
        $dest = Join-Path $t.Root ($full -replace '^([A-Za-z]):', '$1')

        robocopy $full $dest $t.Mode /COPY:DAT /DCOPY:DAT /MT:8 /R:2 /W:5 /XJ /NP /NDL `
            /XD '$RECYCLE.BIN' 'System Volume Information' /UNILOG+:$log | Out-Null
        if ($LASTEXITCODE -ge 8) {
            "!! robocopy exit $LASTEXITCODE for $full -> $dest" | Add-Content $log
            $failed = $true
        }
    }

    Get-ChildItem $logDir -Filter *.log |
        Where-Object LastWriteTime -lt (Get-Date).AddDays(-$KeepLogDays) |
        Remove-Item -Force
}

exit [int]$failed
