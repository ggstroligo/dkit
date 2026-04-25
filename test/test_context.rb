require_relative "test_helper"

class TestContext < Minitest::Test
  include TestSupport

  def test_context_struct_fields
    ctx = Dkit::Context.new(
      project_root: "/projects/app",
      container: "my-container",
      user: "dev",
      workspace: "/workspace",
      cwd: "/workspace/app",
      compose_files: ["/projects/app/.devcontainer/docker-compose.yml"]
    )
    assert_equal "/projects/app", ctx.project_root
    assert_equal "my-container", ctx.container
    assert_equal "dev", ctx.user
    assert_equal "/workspace", ctx.workspace
    assert_equal "/workspace/app", ctx.cwd
    assert_equal ["/projects/app/.devcontainer/docker-compose.yml"], ctx.compose_files
  end

  def test_resolve_exits_quietly_when_no_root
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        err = assert_raises(SystemExit) { Dkit.resolve!(quiet: true) }
        assert_equal 1, err.status
      end
    end
  end

  def test_resolve_aborts_with_message_when_no_root
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        _out, err_output = capture_io do
          ex = assert_raises(SystemExit) { Dkit.resolve!(quiet: false) }
          assert_equal 1, ex.status
        end
        assert_match(/no .devcontainer\/devcontainer.json found/, err_output)
      end
    end
  end

  def test_resolve_builds_context_with_stubs
    Dir.mktmpdir do |dir|
      dir = File.realpath(dir)
      create_project(dir)
      compose = <<~YAML
        services:
          app:
            container_name: test-container
            image: ruby:3.2
      YAML
      create_compose_file(dir, compose)

      Dir.chdir(dir) do
        Dkit::Container.stub(:running?, true) do
          ctx = Dkit.resolve!
          assert_equal dir, ctx.project_root
          assert_equal "test-container", ctx.container
          assert_equal "dev", ctx.user
          assert_equal "/workspace", ctx.workspace
          assert_instance_of Array, ctx.compose_files
        end
      end
    end
  end

  def test_resolve_uses_defaults_when_config_minimal
    Dir.mktmpdir do |dir|
      dir = File.realpath(dir)
      json = '{"dockerComposeFile":"docker-compose.yml"}'
      create_project(dir, devcontainer_json: json)
      compose = <<~YAML
        services:
          app:
            container_name: default-container
            image: ruby:3.2
      YAML
      create_compose_file(dir, compose)

      Dir.chdir(dir) do
        Dkit::Container.stub(:resolve_name, "default-container") do
          Dkit::Container.stub(:running?, true) do
            ctx = Dkit.resolve!
            assert_equal "root", ctx.user
            assert_equal "/workspace", ctx.workspace
          end
        end
      end
    end
  end
end
