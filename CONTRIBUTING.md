# Contributing

Thanks for improving IP Guard Service.

## Before opening a pull request

1. Keep changes focused and explain the user-facing impact.
2. Do not add telemetry, credentials, tokens, personal IP addresses, or machine-specific paths.
3. Preserve fail-closed behavior unless the change explicitly updates the documented security model.
4. Run the checks:

   ```powershell
   npm run check
   npm test
   ```

5. Test Windows-service and overlay changes on Windows 10 or 11 when possible.

## Configuration changes

If you add or rename a configuration key, update all of these in the same change:

- `config.json`
- `config.example.json`
- `README.md`
- `README.fa.md`
- the installation guides

## Documentation

Keep user-facing documentation in English and Persian. Technical terms may remain in English when that is clearer, but describe the outcome in both languages.

## Release notes

Every user-visible feature, bug fix, behavior change, or removal must update **both** [`CHANGELOG.md`](CHANGELOG.md) and [`CHANGELOG.fa.md`](CHANGELOG.fa.md) in the same change. Add an Iran-time (`IRST`) timestamp, choose the appropriate category (Added, Fixed, Changed, or Removed), and describe the user-facing result in English and Persian.

## Reporting a bug

Use the bug report template and include Windows version, Node.js version, sanitized logs, current state, and reproducible steps. Never post a public IP address, access token, or account information.
