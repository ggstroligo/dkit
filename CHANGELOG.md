# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2026-04-13

### Added
- Verbose routing messages: when a command is intercepted, prints `[dkit] <cmd> → <container>` to stderr before executing
- `verbose_enabled?` helper that checks both env var and intercept file directive
- Disable per-project: add `verbose: false` to `.devcontainer/dkit-intercept` (committed, shared with team)
- Disable personally: set `DKIT_VERBOSE=0` env var (takes precedence over intercept file)
- `dkit init` now includes `# verbose: false` comment in the generated intercept file

### Changed
- `dkit help` documents verbose configuration options

### Notes
- Compatible with Linux and macOS (no platform-specific dependencies)

## [0.2.0] - 2026-04-13

### Added
- Per-project intercept file (`.devcontainer/dkit-intercept`) replaces global config
- `dkit init` auto-detects Ruby and Node projects and seeds intercept file
- `dkit intercept add/remove/list` subcommands for managing per-project commands
- `dkit root` — print project root without requiring a running container
- `dkit code` — open VS Code attached to devcontainer via `vscode-remote://` URI
- `dkit claude` — run claude interactively inside the container
- `dkit exec` — non-TTY variant of `dkit run` for scripting
- Shell hook (`dkit hook`) with fast-path `chpwd` to avoid redundant root lookups
- `code` and `claude` always intercepted when a devcontainer is active
- `DKIT_PROJECT_ROOT` env var to override project root resolution
- Distributed as a Ruby gem

### Changed
- Container name resolution now tries three strategies: compose YAML `container_name`, docker label query, then `docker compose ps -q`
- Intercept configuration moved from `~/.config/dkit/intercept` to per-project `.devcontainer/dkit-intercept`

## [0.1.0] - 2025-01-01

### Added
- Initial release: basic command routing into devcontainer
- Global intercept file at `~/.config/dkit/intercept`
- `dkit run`, `dkit shell`, `dkit up`, `dkit down`, `dkit logs`
- Shell hook with `chpwd` integration
