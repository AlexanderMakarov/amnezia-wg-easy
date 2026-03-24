# CLAUDE.md

## Mandatory repository testing flow

- End-to-end installation verification is mandatory as part of this repository's test flow.
- Run the Ubuntu-only install verification command **before pushing** any branch:
  - `npm run test:before-push`
- This check is intentionally Ubuntu + apt specific and must fail fast on non-Ubuntu or missing apt.

## Why sudo is required

- The install flow uses `apt`/`apt-get` to update package metadata and install system dependencies.
- Those operations modify privileged system locations (for example package databases and files under `/usr`/`/etc`), so elevated permissions are required.
- For that reason, the e2e install test command prints an explicit sudo requirement message and executes the installer path accordingly.
