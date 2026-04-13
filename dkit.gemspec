Gem::Specification.new do |spec|
  spec.name          = "dkit"
  spec.version       = File.read("bin/dkit")[/VERSION\s*=\s*"([^"]+)"/, 1]
  spec.authors       = ["Augusto Stroligo"]
  spec.summary       = "DevKit CLI: routes shell commands into a running devcontainer"
  spec.description   = "Routes shell commands transparently into a running devcontainer " \
                       "with shell hook integration, per-project intercept lists, " \
                       "VS Code attachment, and docker compose helpers."
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.homepage = "https://github.com/ggstroligo/dkit"
  spec.metadata = {
    "source_code_uri"        => "https://github.com/ggstroligo/dkit",
    "changelog_uri"          => "https://github.com/ggstroligo/dkit/blob/main/CHANGELOG.md",
    "bug_tracker_uri"        => "https://github.com/ggstroligo/dkit/issues",
    "rubygems_mfa_required"  => "true"
  }

  spec.files         = ["bin/dkit", "LICENSE", "README.md", "CHANGELOG.md"]
  spec.executables   = ["dkit"]
  spec.bindir        = "bin"
end
