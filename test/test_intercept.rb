require_relative "test_helper"

class TestIntercept < Minitest::Test
  include TestSupport

  def test_list_returns_commands
    Dir.mktmpdir do |dir|
      create_project(dir)
      create_intercept_file(dir, "rails\nbundle\nrspec\n")
      assert_equal %w[rails bundle rspec], Dkit::Intercept.list(dir)
    end
  end

  def test_list_ignores_comments_and_blanks
    Dir.mktmpdir do |dir|
      create_project(dir)
      create_intercept_file(dir, "# This is a comment\n\nrails\n  \n# Another comment\nbundle\n")
      assert_equal %w[rails bundle], Dkit::Intercept.list(dir)
    end
  end

  def test_list_returns_empty_when_no_file
    Dir.mktmpdir do |dir|
      create_project(dir)
      assert_equal [], Dkit::Intercept.list(dir)
    end
  end

  def test_list_returns_unique
    Dir.mktmpdir do |dir|
      create_project(dir)
      create_intercept_file(dir, "rails\nrails\nbundle\n")
      assert_equal %w[rails bundle], Dkit::Intercept.list(dir)
    end
  end

  def test_list_strips_whitespace
    Dir.mktmpdir do |dir|
      create_project(dir)
      create_intercept_file(dir, "  rails  \n  bundle  \n")
      assert_equal %w[rails bundle], Dkit::Intercept.list(dir)
    end
  end

  def test_add_appends_command
    Dir.mktmpdir do |dir|
      create_project(dir)
      create_intercept_file(dir, "rails\n")
      _out, _err = capture_io { Dkit::Intercept.add(dir, "bundle") }
      assert_includes Dkit::Intercept.list(dir), "bundle"
    end
  end

  def test_add_skips_duplicate
    Dir.mktmpdir do |dir|
      create_project(dir)
      create_intercept_file(dir, "rails\n")
      out, _err = capture_io { Dkit::Intercept.add(dir, "rails") }
      assert_match(/already in the intercept list/, out)
    end
  end

  def test_remove_deletes_command
    Dir.mktmpdir do |dir|
      create_project(dir)
      create_intercept_file(dir, "rails\nbundle\n")
      _out, _err = capture_io { Dkit::Intercept.remove(dir, "rails") }
      refute_includes Dkit::Intercept.list(dir), "rails"
      assert_includes Dkit::Intercept.list(dir), "bundle"
    end
  end

  def test_remove_nonexistent_command
    Dir.mktmpdir do |dir|
      create_project(dir)
      create_intercept_file(dir, "rails\n")
      out, _err = capture_io { Dkit::Intercept.remove(dir, "bundle") }
      assert_match(/is not in the intercept list/, out)
    end
  end

  def test_verbose_enabled_default
    Dir.mktmpdir do |dir|
      create_project(dir)
      create_intercept_file(dir, "rails\n")
      assert Dkit::Intercept.verbose_enabled?(dir)
    end
  end

  def test_verbose_enabled_when_no_file
    Dir.mktmpdir do |dir|
      create_project(dir)
      assert Dkit::Intercept.verbose_enabled?(dir)
    end
  end

  def test_verbose_disabled_by_file
    Dir.mktmpdir do |dir|
      create_project(dir)
      create_intercept_file(dir, "verbose: false\nrails\n")
      refute Dkit::Intercept.verbose_enabled?(dir)
    end
  end

  def test_verbose_disabled_by_env
    Dir.mktmpdir do |dir|
      create_project(dir)
      create_intercept_file(dir, "rails\n")
      ENV["DKIT_VERBOSE"] = "0"
      refute Dkit::Intercept.verbose_enabled?(dir)
    end
  ensure
    ENV.delete("DKIT_VERBOSE")
  end
end
