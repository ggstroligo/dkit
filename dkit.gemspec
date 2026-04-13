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

  spec.files         = ["bin/dkit"]
  spec.executables   = ["dkit"]
  spec.bindir        = "bin"
end
