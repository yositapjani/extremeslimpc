<#
ExtremeSlimPC - Extreme Windows 11 debloat + privacy hardening.
Run in Windows PowerShell as Administrator:
  irm https://raw.githubusercontent.com/yositapjani/extremeslimpc/main/extremeslimpc.ps1 | iex
What it does:
  - Removes 21 bundled apps (user + provisioned) incl. Xbox stack
  - Disables 14 telemetry/sync/Xbox services
  - Disables 8 telemetry/compat scheduled tasks
  - Sets 14 privacy policies (telemetry 0, location Deny, no Start ads,
    no silent app installs, Cortana off, OneDrive blocked, Delivery
    Optimization HTTP-only)
  - Uninstalls OneDrive + removes Edge autostart + OneDrive tasks
What it does NOT touch:
  Microsoft Store, Windows Defender, Windows Update, printing (Spooler),
  Search indexing, SysMain, .NET/VC runtimes, system components.
WARNING: Do not run if you use OneDrive or Xbox/Game Bar. Removed Store
apps can be reinstalled from the Microsoft Store (kept on purpose).
Restore: irm https://raw.githubusercontent.com/yositapjani/extremeslimpc/main/extremeslimpc-restore.ps1 | iex
Log: $env:TEMP\extremeslimpc.log (transcript) + console output.
No reboot required. Sign out/in for all Start/policy effects.
#>
$ErrorActionPreference = 'Continue'
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
  Write-Output 'ERROR: Run this script as Administrator. Right-click PowerShell -> Run as administrator, then paste the command again.'
  return
}
$logPath = Join-Path $env:TEMP 'extremeslimpc.log'
try { Start-Transcript -Path $logPath -Append -ErrorAction Stop | Out-Null } catch { Write-Output 'NOTE: Transcript unavailable, console output only.' }
Write-Output 'EXTREMESLIMPC-START'
Write-Output 'PLAN:'
Write-Output '  - Remove 21 bundled apps (user + provisioned), incl. Xbox stack'
Write-Output '  - Disable 14 services (telemetry, geolocation, maps, CDP, PIM sync, Insider, Xbox)'
Write-Output '  - Disable 8 scheduled tasks (CEIP, Appraiser, compat, location, maps, disk diagnostic)'
Write-Output '  - Set 14 privacy policies (telemetry 0, location Deny, no Start ads, no silent installs, Cortana off, OneDrive blocked, Delivery Optimization HTTP-only)'
Write-Output '  - Uninstall OneDrive, remove Edge autostart, disable OneDrive tasks'
Write-Output '  - KEEP: Microsoft Store, Windows Defender, Windows Update, Spooler, Search, SysMain, runtimes'
Write-Output '  - WARNING: OneDrive and Xbox/Game Bar will be removed. Removed Store apps can be reinstalled from the Store.'
Write-Output '  - Review the script: https://github.com/yositapjani/extremeslimpc'
if ($env:EXTREMESLIMPC_NO_CONFIRM -ne '1') {
  Write-Output 'Starting in 10 seconds. Press Ctrl+C to cancel.'
  for ($i = 10; $i -gt 0; $i--) {
    Write-Progress -Activity 'ExtremeSlimPC' -Status "Starting in $i seconds (Ctrl+C to cancel)" -PercentComplete ((10 - $i) * 10)
    Start-Sleep -Seconds 1
  }
  Write-Progress -Activity 'ExtremeSlimPC' -Completed
}
Write-Output ("TIME: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
$c0 = Get-PSDrive C
Write-Output ("C-FREE-BEFORE-GB: {0}" -f [math]::Round($c0.Free / 1GB, 2))
$removeAppx = @('Microsoft.BingNews', 'Microsoft.BingWeather', 'Microsoft.MicrosoftSolitaireCollection', 'Microsoft.Todos', 'Microsoft.WindowsAlarms', 'Microsoft.WindowsSoundRecorder', 'Microsoft.ZuneMusic', 'Microsoft.WindowsFeedbackHub', 'Microsoft.GetHelp', 'Microsoft.MicrosoftOfficeHub', 'Microsoft.PowerAutomateDesktop', 'Clipchamp.Clipchamp', 'Microsoft.Windows.DevHome', 'MSTeams', 'Microsoft.YourPhone', 'Microsoft.OutlookForWindows', 'Microsoft.GamingApp', 'Microsoft.Xbox.TCUI', 'Microsoft.XboxGamingOverlay', 'Microsoft.XboxIdentityProvider', 'Microsoft.XboxSpeechToTextOverlay', 'Microsoft.XboxGameCallableUI')
Write-Output '=== REMOVE APPX USER ==='
foreach ($name in $removeAppx) {
  try {
    $pkgs = Get-AppxPackage -Name $name -ErrorAction Stop
    if (-not $pkgs) { Write-Output ("APPX-NOT-INSTALLED: {0}" -f $name); continue }
    foreach ($p in $pkgs) { Remove-AppxPackage -Package $p.PackageFullName -ErrorAction Stop }
    $left = Get-AppxPackage -Name $name -ErrorAction SilentlyContinue
    if ($left) { Write-Output ("APPX-PARTIAL: {0} still {1}" -f $name, @($left).Count) } else { Write-Output ("APPX-REMOVED: {0}" -f $name) }
  } catch { Write-Output ("APPX-FAILED: {0} {1}" -f $name, $_.Exception.Message) }
}
Write-Output '=== REMOVE APPX PROVISIONED ==='
foreach ($name in $removeAppx) {
  try {
    $provs = Get-AppxProvisionedPackage -Online -ErrorAction Stop | Where-Object { $_.DisplayName -eq $name }
    if (-not $provs) { Write-Output ("PROV-NOT-INSTALLED: {0}" -f $name); continue }
    foreach ($pv in $provs) { Remove-AppxProvisionedPackage -Online -PackageName $pv.PackageName -ErrorAction Stop }
    Write-Output ("PROV-REMOVED: {0}" -f $name)
  } catch { Write-Output ("PROV-FAILED: {0} {1}" -f $name, $_.Exception.Message) }
}
Write-Output '=== SWEEP TASKS ONEDRIVE ==='
try {
  foreach ($t in (Get-ScheduledTask -ErrorAction Stop | Where-Object { $_.TaskName -like '*OneDrive*' })) {
    try { Disable-ScheduledTask -TaskPath $t.TaskPath -TaskName $t.TaskName -ErrorAction Stop | Out-Null; Write-Output ("TASK-DISABLED: {0}{1}" -f $t.TaskPath, $t.TaskName) } catch { Write-Output ("TASK-FAILED: {0}{1} {2}" -f $t.TaskPath, $t.TaskName, $_.Exception.Message) }
  }
} catch { Write-Output ("TASK-SWEEP-FAILED: {0}" -f $_.Exception.Message) }
Write-Output '=== ONEDRIVE UNINSTALL ==='
try {
  $setup = "$env:SystemRoot\System32\OneDriveSetup.exe"
  if (Test-Path $setup) {
    Start-Process -FilePath $setup -ArgumentList '/uninstall' -ErrorAction Stop
    Start-Sleep -Seconds 20
    Write-Output 'ONEDRIVE: UNINSTALL-LAUNCHED'
  } else { Write-Output 'ONEDRIVE: SETUP-NOT-FOUND' }
} catch { Write-Output ("ONEDRIVE-FAILED: {0}" -f $_.Exception.Message) }
try {
  $odFolder = "$env:USERPROFILE\OneDrive"
  if (Test-Path $odFolder) {
    $items = Get-ChildItem -Path $odFolder -Force -ErrorAction SilentlyContinue
    $nonIni = @($items | Where-Object { $_.Name -ne 'desktop.ini' })
    if (-not $items -or $nonIni.Count -eq 0) {
      Remove-Item -Path $odFolder -Recurse -Force -ErrorAction Stop
      Write-Output 'ONEDRIVE-FOLDER: REMOVED-EMPTY-OR-ONLY-DESKTOPINI'
    } else {
      $names = ($nonIni | ForEach-Object { $_.Name }) -join ', '
      Write-Output ("ONEDRIVE-FOLDER: LEFT-NONEMPTY items={0} [{1}]" -f $nonIni.Count, $names)
    }
  } else { Write-Output 'ONEDRIVE-FOLDER: ALREADY-GONE' }
} catch { Write-Output ("ONEDRIVE-FOLDER-FAILED: {0}" -f $_.Exception.Message) }
Write-Output '=== SERVICES DISABLE ==='
$disableSvc = @('DiagTrack', 'dmwappushservice', 'lfsvc', 'MapsBroker', 'CDPUserSvc', 'OneSyncSvc', 'PimIndexMaintenanceSvc', 'UnistoreSvc', 'UserDataSvc', 'wisvc', 'XblAuthManager', 'XblGameSave', 'XboxNetApiSvc', 'XboxGipSvc')
foreach ($n in $disableSvc) {
  try {
    $s = Get-Service -Name $n -ErrorAction Stop
    Stop-Service -Name $n -Force -ErrorAction SilentlyContinue
    Set-Service -Name $n -StartupType Disabled -ErrorAction Stop
    $after = Get-Service -Name $n -ErrorAction SilentlyContinue
    Write-Output ("SVC-DISABLED: {0} Status={1} Start={2}" -f $n, $after.Status, $after.StartType)
  } catch { Write-Output ("SVC-FAILED: {0} {1}" -f $n, $_.Exception.Message) }
}
Write-Output '=== TASKS DISABLE ==='
$disableTasks = @('\Microsoft\Windows\Customer Experience Improvement Program\|Consolidator', '\Microsoft\Windows\Customer Experience Improvement Program\|UsbCeip', '\Microsoft\Windows\Application Experience\|Microsoft Compatibility Appraiser', '\Microsoft\Windows\Application Experience\|Microsoft Compatibility Appraiser Exp', '\Microsoft\Windows\Application Experience\|PcaPatchDbTask', '\Microsoft\Windows\Application Experience\|StartupAppTask', '\Microsoft\Windows\Location\|WindowsActionDialog', '\Microsoft\Windows\Maps\|MapsToastTask', '\Microsoft\Windows\DiskDiagnostic\|Microsoft-Windows-DiskDiagnosticDataCollector')
foreach ($pair in $disableTasks) {
  $parts = $pair.Split('|')
  $tp = $parts[0]
  $tn = $parts[1]
  try {
    $t = Get-ScheduledTask -TaskPath $tp -TaskName $tn -ErrorAction Stop
    if ($t.State -eq 'Disabled') { Write-Output ("TASK-ALREADY-DISABLED: {0}{1}" -f $tp, $tn) } else { Disable-ScheduledTask -TaskPath $tp -TaskName $tn -ErrorAction Stop | Out-Null; Write-Output ("TASK-DISABLED: {0}{1}" -f $tp, $tn) }
  } catch { Write-Output ("TASK-FAILED: {0}{1} {2}" -f $tp, $tn, $_.Exception.Message) }
}
Write-Output '=== REGISTRY POLICIES ==='
function Set-Reg($path, $name, $value, $type) {
  try {
    if (-not (Test-Path $path)) { New-Item -Path $path -Force -ErrorAction Stop | Out-Null }
    Set-ItemProperty -Path $path -Name $name -Value $value -Type $type -Force -ErrorAction Stop
    $v = (Get-ItemProperty -Path $path -Name $name -ErrorAction Stop).$name
    Write-Output ("REG-SET: {0} {1} = {2}" -f $path, $name, $v)
  } catch { Write-Output ("REG-FAILED: {0} {1} {2}" -f $path, $name, $_.Exception.Message) }
}
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0 'DWord'
Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' 'AllowTelemetry' 0 'DWord'
Set-Reg 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0 'DWord'
Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location' 'Value' 'Deny' 'String'
Set-Reg 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'ContentDeliveryAllowed' 0 'DWord'
Set-Reg 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SilentInstalledAppsEnabled' 0 'DWord'
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableActivityFeed' 0 'DWord'
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'AllowCortana' 0 'DWord'
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive' 'DisableFileSyncNGSC' 1 'DWord'
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' 'DODownloadMode' 0 'DWord'
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 1 'DWord'
Set-Reg 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' 'BingSearchEnabled' 0 'DWord'
Set-Reg 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' 'CortanaConsent' 0 'DWord'
Set-Reg 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy' 'TailoredExperiencesWithDiagnosticDataEnabled' 0 'DWord'
Write-Output '=== STARTUP CLEANUP ==='
try {
  $runPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
  $props = Get-ItemProperty -Path $runPath -ErrorAction Stop
  foreach ($prop in ($props.PSObject.Properties | Where-Object { $_.Name -like 'MicrosoftEdgeAutoLaunch*' -or $_.Name -eq 'OneDrive' -or $_.Name -eq 'OneDriveSetup' })) {
    try { Remove-ItemProperty -Path $runPath -Name $prop.Name -Force -ErrorAction Stop; Write-Output ("RUN-REMOVED: {0}" -f $prop.Name) } catch { Write-Output ("RUN-FAILED: {0} {1}" -f $prop.Name, $_.Exception.Message) }
  }
} catch { Write-Output ("RUN-FAILED: {0}" -f $_.Exception.Message) }
Write-Output '=== VERIFY KEPT ==='
foreach ($n in @('WinDefend', 'wuauserv', 'UsoSvc', 'Spooler')) {
  $s = Get-Service -Name $n -ErrorAction SilentlyContinue
  if ($s) { Write-Output ("KEPT: {0} Status={1} Start={2}" -f $n, $s.Status, $s.StartType) } else { Write-Output ("KEPT-MISSING: {0}" -f $n) }
}
try {
  $mp = Get-MpComputerStatus
  Write-Output ("DEFENDER: Antivirus={0} RealTime={1}" -f $mp.AntivirusEnabled, $mp.RealTimeProtectionEnabled)
} catch { Write-Output 'DEFENDER: QUERY-FAILED' }
$c1 = Get-PSDrive C
Write-Output ("C-FREE-AFTER-GB: {0}" -f [math]::Round($c1.Free / 1GB, 2))
Write-Output 'EXTREMESLIMPC-DONE'
Write-Output 'Restore (re-enable services/tasks, undo policies; apps must be reinstalled from the Store):'
Write-Output '  irm https://raw.githubusercontent.com/yositapjani/extremeslimpc/main/extremeslimpc-restore.ps1 | iex'
try { Stop-Transcript -ErrorAction SilentlyContinue | Out-Null } catch { }
