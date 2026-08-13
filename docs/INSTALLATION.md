# Installation and operation

## Before you install

IP Guard intentionally blocks listed applications whenever it cannot prove that the current public IP belongs to a trusted country. Read these points first:

- Select the country allowlist deliberately. Do not rely on the default list for your own security policy.
- List only applications that are safe to force-close. `taskkill /F /T` can discard unsaved work.
- The first service state is `UNSAFE`, until a lookup succeeds. Close listed applications before the first install.
- Install the service only on a machine you administer.

## 1. Get the source

Clone the repository or download the source archive, then open a terminal in the project folder:

```powershell
git clone https://github.com/<your-account>/ip-guard-service.git
cd ip-guard-service
```

Replace the placeholder repository URL with the URL of your fork/repository.

## 2. Configure the guard

Copy the example only if you need a fresh starting point:

```powershell
Copy-Item config.example.json config.json
```

Edit `config.json`:

```json
{
  "trustedCountryCodes": ["US", "GB"],
  "processesToKill": ["ChatGPT.exe", "claude.exe", "Perplexity.exe"],
  "checkIntervalMs": 5000,
  "killIntervalMs": 100
}
```

Country codes must be two-letter ISO 3166-1 alpha-2 codes. Executable names must match the **Name** column in Task Manager → Details.

## 3. Install dependencies

Run [`1-install-dependencies.bat`](../1-install-dependencies.bat), or run:

```powershell
npm install
npm test
```

`npm test` validates the checked-in project structure and configuration schema. It does not start the service or kill any process.

## 4. Install the Windows service

Right-click [`2-install-service.bat`](../2-install-service.bat) and choose **Run as administrator**.

The installer creates `IPGuardService`, configured through `node-windows`, and starts it. Inspect it from `services.msc` or run:

```powershell
Get-Service IPGuardService
```

## 5. Install the desktop alert

Run [`install-overlay.bat`](../install-overlay.bat) from every Windows user account that should receive the alert. It:

1. Downloads Vazirmatn Regular/Bold only if they are not already beside the project files.
2. Creates a Startup shortcut for the current user.
3. Starts `alert.ps1` with a hidden PowerShell host.

The alert process reads `C:\ProgramData\IPGuardService\status.json`; it is intentionally separate from the service because Windows services run in Session 0 and cannot safely show normal desktop UI.

## 6. Verify the state

Run [`5-view-log.bat`](../5-view-log.bat). It refreshes the current state each second:

- **Green / `TRUSTED`** — a trusted country was confirmed; listed applications may run.
- **Red / `UNSAFE`** — protection is active; listed applications are force-closed.
- **Yellow** — status file unavailable or being updated; confirm the service is running.

The raw files are:

| File | Purpose |
| --- | --- |
| `C:\ProgramData\IPGuardService\status.json` | Current service decision. |
| `C:\ProgramData\IPGuardService\ipguard.log` | State changes, first lookup failure, recovery, successful kills. |

## Updating configuration

1. Edit `config.json`.
2. Run [`4-restart-service.bat`](../4-restart-service.bat) as Administrator.
3. Check the state again with `5-view-log.bat`.

## Uninstalling

1. Run [`3-stop-and-uninstall-service.bat`](../3-stop-and-uninstall-service.bat) as Administrator.
2. Run [`uninstall-overlay.bat`](../uninstall-overlay.bat) from each user account where the alert was installed.

The scripts do not remove `C:\ProgramData\IPGuardService\` logs/status files. Remove them manually only if you no longer need the diagnostic history.
