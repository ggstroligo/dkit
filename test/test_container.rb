require_relative "test_helper"

class TestContainer < Minitest::Test
  include TestSupport

  def test_load_dc_config_parses_json
    Dir.mktmpdir do |dir|
      create_project(dir)
      cfg = Dkit::Container.load_dc_config(dir)
      assert_equal "app", cfg["service"]
      assert_equal "/workspace", cfg["workspaceFolder"]
      assert_equal "dev", cfg["remoteUser"]
    end
  end

  def test_load_dc_config_strips_line_comments
    Dir.mktmpdir do |dir|
      json = <<~JSON
        {
          // this is a comment
          "service": "web"
        }
      JSON
      create_project(dir, devcontainer_json: json)
      cfg = Dkit::Container.load_dc_config(dir)
      assert_equal "web", cfg["service"]
    end
  end

  def test_load_dc_config_strips_block_comments
    Dir.mktmpdir do |dir|
      json = <<~JSON
        {
          /* block comment */
          "service": "api"
        }
      JSON
      create_project(dir, devcontainer_json: json)
      cfg = Dkit::Container.load_dc_config(dir)
      assert_equal "api", cfg["service"]
    end
  end

  def test_resolve_name_from_compose_yaml
    Dir.mktmpdir do |dir|
      create_project(dir)
      compose = <<~YAML
        services:
          app:
            container_name: my-app-container
            image: ruby:3.2
      YAML
      create_compose_file(dir, compose)
      cfg = Dkit::Container.load_dc_config(dir)
      name = Dkit::Container.resolve_name(dir, cfg)
      assert_equal "my-app-container", name
    end
  end

  def test_resolve_name_returns_nil_when_no_compose
    Dir.mktmpdir do |dir|
      json = '{"service":"app","dockerComposeFile":"nonexistent.yml"}'
      create_project(dir, devcontainer_json: json)
      cfg = Dkit::Container.load_dc_config(dir)

      # Stub docker to return nil (no running containers)
      Dkit::Container.stub(:docker, nil) do
        name = Dkit::Container.resolve_name(dir, cfg)
        assert_nil name
      end
    end
  end

  def test_cwd_relative_path
    Dir.mktmpdir do |dir|
      dir = File.realpath(dir)
      subdir = File.join(dir, "app", "models")
      FileUtils.mkdir_p(subdir)
      Dir.chdir(subdir) do
        result = Dkit::Container.cwd(dir, "/workspace")
        assert_equal "/workspace/app/models", result
      end
    end
  end

  def test_cwd_at_project_root
    Dir.mktmpdir do |dir|
      dir = File.realpath(dir)
      Dir.chdir(dir) do
        result = Dkit::Container.cwd(dir, "/workspace")
        assert_equal "/workspace/.", result
      end
    end
  end

  def test_cwd_outside_project_falls_back
    Dir.mktmpdir do |project_dir|
      Dir.mktmpdir do |other_dir|
        other_dir = File.realpath(other_dir)
        Dir.chdir(other_dir) do
          result = Dkit::Container.cwd(File.realpath(project_dir), "/workspace")
          assert_equal "/workspace", result
        end
      end
    end
  end

  def test_running_with_stub
    Dkit::Container.stub(:docker, "running") do
      assert Dkit::Container.running?("test-container")
    end
  end

  def test_not_running_with_stub
    Dkit::Container.stub(:docker, "exited") do
      refute Dkit::Container.running?("test-container")
    end
  end
end
