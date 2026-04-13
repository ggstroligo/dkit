# Contributing to dkit

Bug reports and pull requests are welcome on GitHub at https://github.com/ggstroligo/dkit.

## Reporting bugs

Open an issue including:
- dkit version (`dkit version`)
- Ruby version (`ruby --version`)
- Docker version (`docker --version`)
- Your `.devcontainer/devcontainer.json` (redact sensitive values)
- The command you ran and the full output

## Development setup

```sh
git clone https://github.com/ggstroligo/dkit
cd dkit
```

The project has no runtime dependencies — `bin/dkit` runs directly:

```sh
ruby bin/dkit help
```

To build and install locally:

```sh
gem build dkit.gemspec
gem install dkit-*.gem
```

## Submitting changes

1. Fork the repository
2. Create a branch: `git checkout -b fix/describe-the-fix`
3. Make your changes in `bin/dkit`
4. Update `CHANGELOG.md` under `[Unreleased]`
5. Bump `VERSION` in `bin/dkit` if appropriate
6. Open a pull request

## Versioning

dkit follows [Semantic Versioning](https://semver.org). The version is defined in `bin/dkit`:

```ruby
VERSION = "x.y.z"
```

Patch: bug fixes. Minor: new commands or features, backwards-compatible. Major: breaking changes to CLI interface or shell hook behavior.
