# Troubleshooting

## The status viewer says the status file is unavailable

1. Run `Get-Service IPGuardService` in an elevated PowerShell window.
2. If it is stopped, run `4-restart-service.bat` as Administrator.
3. Inspect `C:\ProgramData\IPGuardService\ipguard.log`.
4. Confirm that the service account can write to `C:\ProgramData\IPGuardService\`.

## Protected applications are closed immediately after service installation

This is expected until the first successful lookup confirms an allowlisted country. Open `5-view-log.bat`; if the state stays `UNSAFE`, read its reason and inspect the service log.

## The state remains unsafe after a VPN reconnect

- Wait for the next `checkIntervalMs` cycle.
- Confirm that at least one `ipApiEndpoints` URL is reachable from that VPN exit node.
- Do not remove `Connection: close` behavior from the service; it is intentional.
- Lower `checkIntervalMs` only after considering rate limits of the configured providers.

## The desktop alert does not appear

- Run `install-overlay.bat` in the same Windows account that should see it.
- Confirm `alert.ps1`, `Vazirmatn-Regular.ttf`, and `Vazirmatn-Bold.ttf` are present in the project directory.
- Check for `C:\ProgramData\IPGuardService\overlay.pid` while the overlay is running.
- Re-run `install-overlay.bat`; it stops the previous project overlay before creating a new Startup shortcut.

## A program is not being terminated

- Open Task Manager → Details and use the exact filename shown in the **Name** column.
- Add only the `.exe` filename, not a full path.
- Restart the service after changing `config.json`.
- Check whether the application runs with a higher integrity level or through a different user context.

## The service will not install

- Verify Node.js 18+ with `node --version`.
- Run `npm install` first.
- Run the install batch file as Administrator.
- If a previous service exists, use `3-stop-and-uninstall-service.bat`, then install again.
