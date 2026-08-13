# Privacy

IP Guard sends a request to one or more configured public IP-lookup endpoints to determine the public IP and country code. The default endpoints are listed in `config.json`.

## Data involved

- Your network request necessarily exposes your public IP address to the endpoint you contact.
- The endpoint may receive ordinary HTTP metadata such as request time and user-agent information.
- The service stores the latest IP, country code, state, reason, and timestamps locally in `C:\ProgramData\IPGuardService\status.json` and `ipguard.log`.

## Your control

- Replace `ipApiEndpoints` with providers you trust, or your own endpoint.
- Choose a different `logFile` and `statusFile` location if required by your environment.
- Remove local log/status files after uninstalling if you do not need diagnostic history.

The included HTTP `ip-api.com` fallback is unencrypted. Keep it only if you accept that trade-off, or replace/remove it in `config.json`.
