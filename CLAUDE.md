# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What is dkit

A Ruby CLI gem that transparently routes shell commands from the host into a running Docker devcontainer. It uses zsh shell hooks to intercept commands, per-project intercept lists, and automatic project/container detection.

## Project structure

This is a single-file CLI tool. All logic lives in `bin/dkit` (~470 lines, pure Ruby, zero external dependencies). There is no `lib/` directory, no classes or modules — just procedural functions and one `Context` struct.

## Common commands

```bash
# Run during development
ruby bin/dkit help

# Build and install locally
gem build dkit.gemspec && gem install dkit-*.gem

# Test manually (no automated test suite exists)
ruby bin/dkit intercept list
ruby bin/dkit shell
```

## Architecture

**Entry point:** `bin/dkit` parses `ARGV[0]` and routes to the matching `cmd_*` function.

**Core flow:**
1. `find_project_root()` — walks up from CWD looking for `.devcontainer/devcontainer.json`
2. `resolve!()` — builds a `Context` struct with project root, container name, user, workspace, CWD mapping, and compose files
3. `cmd_*` functions — execute docker commands using the resolved context

**Container resolution** (`resolve_container_name`) uses three strategies in order:
1. Parse `docker-compose.yml` service name
2. Docker inspect by devcontainer label
3. `docker compose ps`

**Intercept system:** The shell hook (`cmd_hook`) emits zsh `preexec` code. Commands listed in `.devcontainer/dkit-intercept` get routed into the container instead of running on the host. The intercept file also supports a `verbose:` setting.

**Version** is defined as `VERSION = "x.y.z"` near the top of `bin/dkit` and read by the gemspec.

## Key conventions

- No external gem dependencies — stdlib only (json, yaml, open3, fileutils, shellwords)
- The gemspec reads the version directly from `bin/dkit`
- Platform support: macOS and Linux (uses `sed` flag detection for compatibility)
- Requires Ruby >= 2.7.0
