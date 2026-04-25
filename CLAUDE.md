# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What is dkit

A Ruby CLI gem that transparently routes shell commands from the host into a running Docker devcontainer. It uses zsh shell hooks to intercept commands, per-project intercept lists, and automatic project/container detection.

## Project structure

Modular Ruby gem under the `Dkit` namespace. Zero external dependencies (stdlib only).

```
bin/dkit                    # Thin entry point (~3 lines)
lib/dkit.rb                 # Module entry point, requires/autoloads
lib/dkit/version.rb         # Dkit::VERSION
lib/dkit/project.rb         # Dkit::Project — find_project_root, constants
lib/dkit/intercept.rb       # Dkit::Intercept — intercept file CRUD, verbose
lib/dkit/container.rb       # Dkit::Container — docker helper, config, resolution (autoloaded)
lib/dkit/context.rb         # Dkit::Context struct + Dkit.resolve!
lib/dkit/shell_hook.rb      # Dkit::ShellHook — zsh hook generation
lib/dkit/commands.rb        # Dkit::Commands — all cmd_* + dispatch
test/                       # Minitest suite
```

## Common commands

```bash
# Run during development
ruby bin/dkit help

# Run tests
rake test

# Build and install locally
gem build dkit.gemspec && gem install dkit-*.gem

# Manual testing
ruby bin/dkit intercept list
ruby bin/dkit shell
```

## Architecture

**Entry point:** `bin/dkit` requires `lib/dkit` and calls `Dkit::Commands.dispatch(ARGV)`.

**Module responsibilities:**
- `Dkit::Project` — walks up from CWD looking for `.devcontainer/devcontainer.json`
- `Dkit::Container` — docker CLI wrapper, config loading, container name resolution (3 strategies), running check, CWD mapping. **Autoloaded** to avoid loading json/yaml on hot-path commands.
- `Dkit::Context` — struct with resolved devcontainer state. `Dkit.resolve!` orchestrates Project + Container.
- `Dkit::Intercept` — CRUD for `.devcontainer/dkit-intercept` + verbose control
- `Dkit::ShellHook` — generates the zsh hook code (~130 lines of zsh)
- `Dkit::Commands` — all `cmd_*` methods + dispatch table

**Container resolution** (`Dkit::Container.resolve_name`) uses three strategies in order:
1. Parse `docker-compose.yml` service name
2. Docker inspect by devcontainer label
3. `docker compose ps`

**Intercept system:** The shell hook (`cmd_hook`) emits zsh `preexec` code. Commands listed in `.devcontainer/dkit-intercept` get routed into the container instead of running on the host. The intercept file also supports a `verbose:` setting.

**Version** is defined in `lib/dkit/version.rb` and read by the gemspec.

## Key conventions

- No external gem dependencies — stdlib only (json, yaml, fileutils, shellwords, pathname)
- The gemspec reads the version from `lib/dkit/version.rb`
- `Dkit::Container` is autoloaded to keep hot-path commands fast (no json/yaml parsing)
- Platform support: macOS and Linux
- Requires Ruby >= 2.7.0
- Tests use minitest (stdlib)
