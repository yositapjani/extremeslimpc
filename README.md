# ExtremeSlimPC

Extreme Windows 11 debloat + privacy hardening, as a single copy-paste command. This is the exact process used to slim a fresh Windows 11 Pro install: bundled apps removed, telemetry and sync services stopped, telemetry tasks disabled, and privacy policies set. No mystery tool, no background service: one readable PowerShell script.

## Run it

Run in **Windows PowerShell as Administrator** (right-click PowerShell -> Run as administrator), then paste:

```powershell
irm https://raw.githubusercontent.com/yositapjani/extremeslimpc/main/extremeslimpc.ps1 | iex
```

The script prints its plan, waits 10 seconds so you can cancel with Ctrl+C, then works through every section and logs to `$env:TEMP\extremeslimpc.log`. No reboot is required. Sign out and back in for all Start menu and policy effects to show.

Review the script before you run it: [extremeslimpc.ps1](extremeslimpc.ps1). To skip the 10-second wait (automation only), set `$env:EXTREMESLIMPC_NO_CONFIRM = '1'` first.

## What it removes

Bundled apps, user install and provisioned package (so they do not come back for new users):

- Bing News, Bing Weather, Solitaire Collection, To Do, Alarms, Sound Recorder, Zune Music (Groove)
- Feedback Hub, Get Help, Office Hub, Power Automate Desktop, Clipchamp, DevHome
- Teams, Phone Link (YourPhone), Outlook for Windows (new Outlook)
- Xbox stack: Gaming App, Xbox TCUI, Xbox Gaming Overlay, Xbox Identity Provider, Xbox Speech To Text Overlay, Xbox Game Callable UI (on builds where this system component can be removed; on others it stays, inert without the rest of the stack)

## What it disables

Services (stopped + StartupType Disabled):

- DiagTrack (Connected User Experiences and Telemetry), dmwappushservice (WAP Push)
- lfsvc (Geolocation), MapsBroker (Downloaded Maps Manager)
- CDPUserSvc, OneSyncSvc, PimIndexMaintenanceSvc, UnistoreSvc, UserDataSvc (Connected Devices / contact and PIM sync)
- wisvc (Windows Insider Service)
- XblAuthManager, XblGameSave, XboxNetApiSvc, XboxGipSvc (Xbox services)

Scheduled tasks (Disabled):

- Customer Experience Improvement Program: Consolidator, UsbCeip
- Application Experience: Microsoft Compatibility Appraiser, PcaPatchDbTask, StartupAppTask
- Location: WindowsActionDialog
- Maps: MapsToastTask
- DiskDiagnostic: Microsoft-Windows-DiskDiagnosticDataCollector

## What it sets

Registry policies (verified by read-back in the script):

- Telemetry: `AllowTelemetry = 0` (both policy locations)
- Location consent: `Deny`
- Advertising ID: off
- Start suggestions and silent app installs: off (`ContentDeliveryAllowed = 0`, `SilentInstalledAppsEnabled = 0`)
- Activity Feed: off, Cortana policy: off, Bing search in Start: off, Cortana consent: off, tailored experiences with diagnostic data: off
- OneDrive sync blocked: `DisableFileSyncNGSC = 1`
- Delivery Optimization: HTTP only (`DODownloadMode = 0`, no peer-to-peer update sharing)
- Consumer features: off (`DisableWindowsConsumerFeatures = 1`)

Plus startup cleanup (Edge autostart and OneDrive autostart entries removed) and OneDrive tasks disabled.

## OneDrive and Xbox

OneDrive is uninstalled (via the built-in OneDriveSetup) and blocked by policy. **Your files are not deleted**: if your OneDrive folder contains anything other than `desktop.ini`, the folder is left untouched and the script tells you what is in it. Do not run this if you depend on OneDrive sync or on Xbox / Game Bar.

## What it does NOT touch

- Microsoft Store (kept on purpose, so removed apps can be reinstalled)
- Windows Defender (antivirus + real-time protection stay on)
- Windows Update
- Printing (Spooler stays on)
- Search indexing, SysMain, .NET and Visual C++ runtimes, system components
- Your files, your Steam library, your drivers

## Restore

To undo the services, tasks, and policies (apps must be reinstalled from the Store yourself), run as Administrator:

```powershell
irm https://raw.githubusercontent.com/yositapjani/extremeslimpc/main/extremeslimpc-restore.ps1 | iex
```

Then reboot. To reinstall OneDrive manually, run `$env:SystemRoot\System32\OneDriveSetup.exe`.

## Optional: power plan and pagefile

These are not part of the one-liner above. They were applied on the same machine as a separate optimization step:

- Power plan: High performance (already the setting on many gaming PCs; check with `powercfg /getactivescheme`, set with `powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c`).
- Pagefile for a 16 GB machine: fixed 4096 MB minimum / 8192 MB maximum, automatic management off. Scale to your RAM and disk (on a small SSD, keep the maximum modest). Changing the pagefile requires a reboot to take effect. If you are short on disk, check your current pagefile first: `Get-CimInstance Win32_PageFileUsage`.

## Tested on

Windows 11 Pro, build 26200, 16 GB RAM, single 118 GB SSD. The same commands should work on Windows 10/11 generally, but app names and task names vary slightly by build: the script logs every item as removed, disabled, already-gone, or failed, so you can see exactly what applied on your machine.

## License

MIT. See [LICENSE](LICENSE).
