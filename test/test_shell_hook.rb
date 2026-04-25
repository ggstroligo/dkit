require_relative "test_helper"

class TestShellHook < Minitest::Test
  def setup
    @hook = Dkit::ShellHook.generate
  end

  def test_generate_contains_reset_function
    assert_match(/_dkit_reset\(\)/, @hook)
  end

  def test_generate_contains_load_function
    assert_match(/_dkit_load\(\)/, @hook)
  end

  def test_generate_contains_chpwd_function
    assert_match(/_dkit_chpwd\(\)/, @hook)
  end

  def test_generate_contains_verbose_fallback
    assert_match(/_dkit_verbose_fallback\(\)/, @hook)
  end

  def test_generate_contains_glob_expand
    assert_match(/_dkit_expand_glob\(\)/, @hook)
  end

  def test_generate_contains_glob_refresh
    assert_match(/_dkit_refresh_globs\(\)/, @hook)
  end

  def test_generate_contains_code_function
    assert_match(/^code\(\)/, @hook)
  end

  def test_generate_contains_claude_function
    assert_match(/^claude\(\)/, @hook)
  end

  def test_generate_registers_chpwd_hook
    assert_match(/add-zsh-hook chpwd _dkit_chpwd/, @hook)
  end

  def test_generate_registers_precmd_hook
    assert_match(/add-zsh-hook precmd _dkit_refresh_globs/, @hook)
  end

  def test_generate_calls_chpwd_on_init
    # Last non-blank line should trigger initial load
    assert_match(/_dkit_chpwd\s*$/, @hook)
  end

  def test_generate_contains_global_variables
    assert_match(/_DKIT_ROOT/, @hook)
    assert_match(/_DKIT_ACTIVE_CMDS/, @hook)
    assert_match(/_DKIT_GLOB_PATTERNS/, @hook)
    assert_match(/_DKIT_GLOB_CMDS/, @hook)
  end
end
