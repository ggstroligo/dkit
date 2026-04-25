require "minitest/autorun"
require "tmpdir"
require "fileutils"
require_relative "../lib/dkit"

module TestSupport
  def create_project(dir, devcontainer_json: '{"service":"app","workspaceFolder":"/workspace","remoteUser":"dev","dockerComposeFile":"docker-compose.yml"}')
    dc_dir = File.join(dir, ".devcontainer")
    FileUtils.mkdir_p(dc_dir)
    File.write(File.join(dc_dir, "devcontainer.json"), devcontainer_json)
    dir
  end

  def create_intercept_file(project_root, content)
    File.write(File.join(project_root, Dkit::DC_INTERCEPT), content)
  end

  def create_compose_file(project_root, content)
    File.write(File.join(project_root, ".devcontainer", "docker-compose.yml"), content)
  end
end
