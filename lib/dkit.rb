module Dkit
  autoload :Container, File.expand_path("dkit/container", __dir__)
end

require_relative "dkit/version"
require_relative "dkit/project"
require_relative "dkit/intercept"
require_relative "dkit/context"
require_relative "dkit/shell_hook"
require_relative "dkit/commands"
