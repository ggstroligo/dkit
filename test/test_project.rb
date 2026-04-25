require_relative "test_helper"

class TestProject < Minitest::Test
  include TestSupport

  def test_find_root_with_devcontainer
    Dir.mktmpdir do |dir|
      dir = File.realpath(dir)
      create_project(dir)
      assert_equal dir, Dkit::Project.find_root(from: dir)
    end
  end

  def test_find_root_from_subdirectory
    Dir.mktmpdir do |dir|
      dir = File.realpath(dir)
      create_project(dir)
      subdir = File.join(dir, "app", "models")
      FileUtils.mkdir_p(subdir)
      assert_equal dir, Dkit::Project.find_root(from: subdir)
    end
  end

  def test_find_root_not_found
    Dir.mktmpdir do |dir|
      assert_nil Dkit::Project.find_root(from: dir)
    end
  end

  def test_find_root_with_env_cache
    Dir.mktmpdir do |dir|
      create_project(dir)
      ENV["DKIT_PROJECT_ROOT"] = dir
      assert_equal dir, Dkit::Project.find_root(from: "/tmp")
    end
  ensure
    ENV.delete("DKIT_PROJECT_ROOT")
  end

  def test_find_root_with_invalid_env_cache
    Dir.mktmpdir do |dir|
      ENV["DKIT_PROJECT_ROOT"] = "/nonexistent/path"
      assert_nil Dkit::Project.find_root(from: dir)
    end
  ensure
    ENV.delete("DKIT_PROJECT_ROOT")
  end

  def test_find_root_with_empty_env_cache
    Dir.mktmpdir do |dir|
      dir = File.realpath(dir)
      create_project(dir)
      ENV["DKIT_PROJECT_ROOT"] = ""
      assert_equal dir, Dkit::Project.find_root(from: dir)
    end
  ensure
    ENV.delete("DKIT_PROJECT_ROOT")
  end
end
