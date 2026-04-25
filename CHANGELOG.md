# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0] - 2026-04-24

### Changed
- **Breaking:** Refactored single-file CLI (`bin/dkit`, ~560 lines) into modular structure under `Dkit` namespace (`lib/dkit/`)
- `bin/dkit` is now a 3-line entry point that delegates to `Dkit::Commands.dispatch`
- `Dkit::Container` is autoloaded — hot-path commands (`dkit root`, `dkit hook`, `dkit help`, `dkit version`) no longer load `json`/`yaml` parsers
- Gemspec reads version from `lib/dkit/version.rb` instead of `bin/dkit`

### Added
- Minitest test suite: 64 tests, 154 assertions covering all modules
- `Rakefile` with `rake test` task
- Modules: `Dkit::Project`, `Dkit::Intercept`, `Dkit::Container`, `Dkit::Context`, `Dkit::ShellHook`, `Dkit::Commands`

### Notes
- No changes to CLI behavior, flags, or intercept file format — fully backwards compatible at the user level
- Zero external dependencies maintained (minitest is stdlib)

## [0.4.1] - 2026-04-13

### Fixed
- `dkit shell` now runs as a subprocess (`system`) instead of replacing the current process (`exec`), so `exit` returns to the host shell instead of closing the terminal

### Changed
- README: added zsh as explicit requirement, documented glob/wildcard intercept patterns, clarified zsh-specific hook mechanisms

## [0.4.0] - 2026-04-13

### Added
- Glob/wildcard patterns in intercept file: `bin/*` intercepts all executables under `bin/` (e.g. `bin/rails`, `bin/rspec`)
- New zsh helpers `_dkit_expand_glob` and `_dkit_refresh_globs` for dynamic function creation from glob patterns
- `precmd` hook automatically picks up new executables and cleans up deleted ones between prompts
- Help text documents glob usage with quoting example

### Notes
- Glob patterns must be quoted to prevent shell expansion: `dkit intercept add 'bin/*'`
- Only executable files are matched (non-executable files like READMEs are skipped)
- Requires `exec zsh` after gem update to reload the shell hook

## [0.3.3] - 2026-04-13

### Changed
- Verbose fallback messages are now printed in red and include a `(fallback)` label: `[dkit] bundle → host (fallback)`

## [0.3.1] - 2026-04-13

### Added
- Verbose fallback message: when a command falls back to the host (container not running), prints `[dkit] <cmd> → host` to stderr if verbose is enabled
- Fallback messages respect the same config as container messages: `verbose: false` in `.devcontainer/dkit-intercept` or `DKIT_VERBOSE=0` env var suppress them

### Notes
- Requires `exec zsh` after gem update to reload the shell hook with the updated function templates

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
