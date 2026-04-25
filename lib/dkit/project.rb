require "pathname"

module Dkit
  DC_CONFIG    = ".devcontainer/devcontainer.json"
  DC_INTERCEPT = ".devcontainer/dkit-intercept"
  SPECIAL_COMMANDS = %w[code claude].freeze

  module Project
    module_function

    def find_root(from: Dir.pwd)
      if (cached = ENV["DKIT_PROJECT_ROOT"]) && !cached.empty? &&
         File.exist?(File.join(cached, DC_CONFIG))
        return cached
      end

      path = Pathname.new(File.realpath(from))
      loop do
        return path.to_s if (path + DC_CONFIG).exist?
        parent = path.parent
        return nil if parent == path
        path = parent
      end
    end
  end
end
