require_relative "test_helper"

class TestCommands < Minitest::Test
  include TestSupport

  def test_dispatch_version
    out, _err = capture_io do
      Dkit::Commands.dispatch(["version"])
    end
    assert_match(/dkit #{Dkit::VERSION}/, out)
  end

  def test_dispatch_version_flag
    out, _err = capture_io do
      Dkit::Commands.dispatch(["--version"])
    end
    assert_match(/dkit #{Dkit::VERSION}/, out)
  end

  def test_dispatch_help
    out, _err = capture_io do
      Dkit::Commands.dispatch(["help"])
    end
    assert_match(/DevKit/, out)
    assert_match(/dkit exec/, out)
  end

  def test_dispatch_help_flag
    out, _err = capture_io do
      Dkit::Commands.dispatch(["--help"])
    end
    assert_match(/DevKit/, out)
  end

  def test_dispatch_nil_shows_help
    out, _err = capture_io do
      Dkit::Commands.dispatch([])
    end
    assert_match(/DevKit/, out)
  end

  def test_dispatch_unknown_command_exits
    _out, err = capture_io do
      ex = assert_raises(SystemExit) { Dkit::Commands.dispatch(["nonexistent"]) }
      assert_equal 1, ex.status
    end
    assert_match(/unknown command/, err)
  end

  def test_cmd_root_prints_root
    Dir.mktmpdir do |dir|
      dir = File.realpath(dir)
      create_project(dir)
      Dir.chdir(dir) do
        out, _err = capture_io { Dkit::Commands.cmd_root }
        assert_equal dir, out.strip
      end
    end
  end

  def test_cmd_root_exits_when_no_project
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        assert_raises(SystemExit) { Dkit::Commands.cmd_root }
      end
    end
  end

  def test_cmd_hook_outputs_zsh
    out, _err = capture_io { Dkit::Commands.cmd_hook }
    assert_match(/_dkit_chpwd/, out)
    assert_match(/_dkit_load/, out)
    assert_match(/_dkit_reset/, out)
    assert_match(/add-zsh-hook/, out)
  end

  def test_cmd_init_creates_file_for_ruby_project
    Dir.mktmpdir do |dir|
      create_project(dir)
      File.write(File.join(dir, "Gemfile"), "source 'https://rubygems.org'")
      Dir.chdir(dir) do
        out, _err = capture_io { Dkit::Commands.cmd_init }
        assert_match(/created/, out)
        list = Dkit::Intercept.list(dir)
        assert_includes list, "rails"
        assert_includes list, "bundle"
        assert_includes list, "rspec"
      end
    end
  end

  def test_cmd_init_creates_file_for_node_project
    Dir.mktmpdir do |dir|
      create_project(dir)
      File.write(File.join(dir, "package.json"), '{}')
      Dir.chdir(dir) do
        out, _err = capture_io { Dkit::Commands.cmd_init }
        assert_match(/created/, out)
        list = Dkit::Intercept.list(dir)
        assert_includes list, "yarn"
        assert_includes list, "node"
        assert_includes list, "npx"
      end
    end
  end

  def test_cmd_init_defaults_to_bash
    Dir.mktmpdir do |dir|
      create_project(dir)
      Dir.chdir(dir) do
        out, _err = capture_io { Dkit::Commands.cmd_init }
        assert_match(/created/, out)
        list = Dkit::Intercept.list(dir)
        assert_includes list, "bash"
      end
    end
  end

  def test_cmd_init_does_not_overwrite
    Dir.mktmpdir do |dir|
      create_project(dir)
      create_intercept_file(dir, "rails\n")
      Dir.chdir(dir) do
        out, _err = capture_io { Dkit::Commands.cmd_init }
        assert_match(/already exists/, out)
      end
    end
  end

  def test_cmd_status_prints_context
    ctx = Dkit::Context.new(
      project_root: "/projects/app",
      container: "my-container",
      user: "dev",
      workspace: "/workspace",
      cwd: "/workspace/app",
      compose_files: ["/projects/app/.devcontainer/docker-compose.yml"]
    )
    out, _err = capture_io { Dkit::Commands.cmd_status(ctx, quiet: false) }
    assert_match(/Project root/, out)
    assert_match(/my-container/, out)
    assert_match(/dev/, out)
    assert_match(%r{/workspace}, out)
  end

  def test_cmd_status_quiet_outputs_nothing
    ctx = Dkit::Context.new(
      project_root: "/projects/app",
      container: "my-container",
      user: "dev",
      workspace: "/workspace",
      cwd: "/workspace/app",
      compose_files: []
    )
    out, _err = capture_io { Dkit::Commands.cmd_status(ctx, quiet: true) }
    assert_empty out
  end

  def test_cmd_intercept_list
    Dir.mktmpdir do |dir|
      create_project(dir)
      create_intercept_file(dir, "rails\nbundle\n")
      Dir.chdir(dir) do
        out, _err = capture_io { Dkit::Commands.cmd_intercept(["list"]) }
        assert_match(/rails/, out)
        assert_match(/bundle/, out)
        assert_match(/Special/, out)
      end
    end
  end

  def test_cmd_intercept_add
    Dir.mktmpdir do |dir|
      create_project(dir)
      create_intercept_file(dir, "rails\n")
      Dir.chdir(dir) do
        _out, _err = capture_io { Dkit::Commands.cmd_intercept(["add", "rspec"]) }
        assert_includes Dkit::Intercept.list(dir), "rspec"
      end
    end
  end

  def test_cmd_intercept_remove
    Dir.mktmpdir do |dir|
      create_project(dir)
      create_intercept_file(dir, "rails\nbundle\n")
      Dir.chdir(dir) do
        _out, _err = capture_io { Dkit::Commands.cmd_intercept(["remove", "rails"]) }
        refute_includes Dkit::Intercept.list(dir), "rails"
      end
    end
  end
end
