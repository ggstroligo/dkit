# dkit

[![Gem Version](https://badge.fury.io/rb/dkit.svg)](https://rubygems.org/gems/dkit)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

DevKit CLI — routes shell commands transparently into a running devcontainer.

When you `cd` into a project, dkit intercepts configured commands (e.g. `rails`, `bundle`, `rspec`) and executes them inside the devcontainer instead of on the host, preserving the correct working directory. When no container is running the commands fall through to the host as normal.

## Requirements

- macOS or Linux
- Ruby >= 2.7
- Docker with Compose v2 (`docker compose`)
- A project with `.devcontainer/devcontainer.json` using `dockerComposeFile` + `service`

## Installation

```sh
gem install dkit
echo 'eval "$(dkit hook)"' >> ~/.zshrc && exec zsh
```

### From source

```sh
gem build dkit.gemspec && gem install dkit-*.gem
```

## Shell integration

The hook registers a `chpwd` listener that loads and unloads command shims as you navigate between projects. Add it once to `~/.zshrc`:

```sh
eval "$(dkit hook)"
```

`code` and `claude` are always intercepted when a devcontainer is active — no configuration needed.

## Project setup

```sh
cd ~/projects/my-app
dkit init
```

`dkit init` detects the project type (Ruby, Node) and creates `.devcontainer/dkit-intercept` with sensible defaults. Commit that file so your whole team gets the same behavior:

```sh
git add .devcontainer/dkit-intercept
git commit -m "chore: add dkit intercept config"
```

### Managing intercepted commands

```sh
dkit intercept list              # show active commands for this project
dkit intercept add terraform     # add a command
dkit intercept remove terraform  # remove a command
exec zsh                         # reload shell to apply changes
```

### Verbose routing messages

By default, dkit prints a line to stderr whenever it intercepts a command:

```
[dkit] rails server → myapp-dev
```

To disable **per project** (committed, shared with the team), add to `.devcontainer/dkit-intercept`:

```
verbose: false
rails
bundle
```

To disable **personally** regardless of project config:

```sh
export DKIT_VERBOSE=0   # add to ~/.zshrc
```

## Usage

```
dkit exec <cmd> [args]      Run command without TTY (scripting/CI)
dkit run  <cmd> [args]      Run command interactively (TTY)
dkit shell                  Open interactive zsh shell in container
dkit code  [path]           Open VS Code attached to devcontainer
dkit claude [args]          Run claude inside container

dkit status                 Show resolved devcontainer context
dkit status --quiet         Exit 0 if running, 1 otherwise (for scripting)
dkit root                   Print project root (no docker required)

dkit up    [service]        docker compose up -d
dkit down  [flags]          docker compose down
dkit logs  [service]        docker compose logs -f

dkit init                   Create .devcontainer/dkit-intercept
dkit intercept list|add|remove <cmd>
dkit hook                   Emit shell hook for ~/.zshrc
dkit version
```

## How it works

1. On `cd`, the shell hook calls `dkit root` to find the nearest `.devcontainer/devcontainer.json`.
2. It reads `.devcontainer/dkit-intercept` and defines a shell function for each listed command.
3. Each function calls `dkit status --quiet` to check if the container is running. If yes, it delegates to `dkit run <cmd>`; otherwise it calls the host binary.
4. `dkit run` resolves the container name from the devcontainer config (via compose YAML, docker labels, or `docker compose ps`) and execs into it at the mirrored working directory.

## devcontainer.json requirements

dkit reads the following fields:

| Field | Default | Purpose |
|---|---|---|
| `service` | `"app"` | Compose service name |
| `dockerComposeFile` | — | Path(s) to compose file(s) |
| `workspaceFolder` | `"/workspace"` | Container working directory root |
| `remoteUser` | `"root"` | User for `docker exec` |

## Environment variables

| Variable | Purpose |
|---|---|
| `DKIT_PROJECT_ROOT` | Override project root resolution (useful in scripts) |
| `DKIT_VERBOSE` | Set to `0` to suppress routing messages globally |

## License

MIT
