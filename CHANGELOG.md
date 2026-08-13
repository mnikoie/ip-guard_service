# Changelog

All user-visible features, fixes, and behavioral changes are recorded here in Iran time (`IRST`, UTC+03:30). The Persian equivalent is [CHANGELOG.fa.md](CHANGELOG.fa.md).

## [2026-08-13 21:45 IRST]

### Added

- Tray option to show whether **IP Guard Tray.exe** starts automatically with Windows, and to add or remove that Startup entry from the right-click menu.
- A bilingual, dated feature and fix history in English and Persian.

### Fixed

- Project relocation is now repaired during service installation: stale local `daemon` files no longer produce a false “already installed” result.

## [2026-08-13 21:30 IRST]

### Added

- GitHub-hosted video player embedded in both READMEs for the Tray setup walkthrough.
- Online video tutorial and language-specific visual quick-start guides.

## [2026-08-13 21:10 IRST]

### Added

- Standalone `IP Guard Tray.exe` with live install/active state markers, color-coded actions, service start/stop/restart controls, and safe project-only dependency removal.
- Persian RTL / English LTR Tray switcher, persisted for each Windows user.
- In-app author/contact dialog and custom user-supplied Tray icon support.
- Native PowerShell/Vazirmatn desktop overlay, color-coded current-status viewer, and bilingual GitHub documentation.

### Fixed

- Service detection now recognizes the actual `node-windows` service name (`ipguardservice.exe`).
- Service removal works even after dependencies have been removed.
- Dependency removal asks whether to remove the installed service too; choosing **No** now removes dependencies only, and **Cancel** changes nothing.

### Changed

- Tray startup launches the standalone executable instead of PowerShell.
- Service descriptions include the developer’s name, mobile number, and email address.

### Removed

- Legacy HTA overlay.
