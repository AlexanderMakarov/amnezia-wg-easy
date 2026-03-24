# AmneziaWG Easy (Native Bun Runtime)

Run and manage AmneziaWG/WireGuard directly on a Linux host (no Docker).

<p align="center">
  <img src="./assets/screenshot.png" width="802" />
</p>

## Features

* All-in-one: AmneziaWG + Web UI.
* Runs as a native systemd service with Bun.
* Uses host-installed `awg`/`wg` and `awg-quick`/`wg-quick`.
* List, create, edit, delete, enable & disable clients.
* Show a client's QR code.
* Download a client's configuration file.
* Statistics for which clients are connected.
* One-time links disabled.
* Prometheus metrics disabled by default.

## Requirements

* Linux host with WireGuard kernel support (`/dev/net/tun`).
* Ubuntu (officially supported; installer validated on ARM64 and x86_64).
* Other Linux distributions may work on a best-effort basis.
* Root access to install service and networking dependencies.

## Install (native)

```bash
git clone https://github.com/AlexanderMakarov/amnezia-wg-easy
cd amnezia-wg-easy
bun run install:machine
```

Why `sudo` is still needed: the install flow configures apt packages, writes to `/opt` and `/etc`, and registers a systemd service.

## Bun-based verification flow

Validate non-Docker install path expectations (APP_DIR + systemd wiring):

```bash
bun run test
```

After install:

```bash
sudoedit /opt/amnezia-wg-easy/.env
sudo systemctl restart amnezia-wg-easy
sudo systemctl status amnezia-wg-easy
```

Generate admin password hash:

```bash
bun src/wgpw.mjs "your-password"
```

## Environment options

The runtime reads `/opt/amnezia-wg-easy/.env`.

| Env                           | Default                        | Example            | Description |
|-------------------------------|--------------------------------|--------------------|-------------|
| `PORT`                        | `51821`                        | `6789`             | TCP port for Web UI |
| `WEBUI_HOST`                  | `0.0.0.0`                      | `127.0.0.1`        | Bind host for web UI |
| `PASSWORD_HASH`               | -                              | `$2y$...`          | Bcrypt hash for UI login |
| `WG_HOST`                     | -                              | `vpn.myserver.com` | Public hostname/IP for generated client configs |
| `WG_PATH`                     | `/etc/amnezia/amneziawg/`      | `/etc/wireguard/`  | Config directory containing `wg0.conf` and `wg0.json` |
| `WG_BIN`                      | `awg` or `wg` (installer set)  | `wg`               | Binary for key generation and runtime status |
| `WG_QUICK_BIN`                | `awg-quick` or `wg-quick`      | `wg-quick`         | Binary for interface up/down and config strip |
| `WG_DEVICE`                   | `eth0`                         | `ens6`             | Outbound interface for post-up/post-down rules |
| `WG_PORT`                     | `51820`                        | `12345`            | Public UDP VPN port |
| `WG_CONFIG_PORT`              | `51820`                        | `12345`            | Endpoint port written to client configs |
| `WG_ENABLE_ONE_TIME_LINKS`    | `false` (fixed)                | -                  | Disabled in this build |
| `ENABLE_PROMETHEUS_METRICS`   | `false`                        | `true`             | Optional `/metrics` endpoints |

## Update

```bash
cd /opt/amnezia-wg-easy
sudo -u amnezia-wg-easy git pull
cd src
sudo -u amnezia-wg-easy bun install --frozen-lockfile --production
sudo systemctl restart amnezia-wg-easy
```

## Thanks

Based on [wg-easy](https://github.com/wg-easy/wg-easy) by Emile Nijssen.  
Uses AmneziaWG integration from [amnezia-wg-easy](https://github.com/spcfox/amnezia-wg-easy) by Viktor Yudov.
