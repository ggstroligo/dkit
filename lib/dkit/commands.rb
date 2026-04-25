module Dkit
  module Commands
    module_function

    def dispatch(argv)
      command = argv.shift&.downcase

      case command
      when "hook"         then cmd_hook
      when "root"         then cmd_root
      when "init"         then cmd_init
      when "intercept"    then cmd_intercept(argv)
      when "status"       then cmd_status_dispatch(argv)
      when "exec"         then cmd_exec(Dkit.resolve!, argv)
      when "run"          then cmd_run(Dkit.resolve!, argv)
      when "shell"        then cmd_shell(Dkit.resolve!)
      when "claude"       then cmd_claude(Dkit.resolve!, argv)
      when "code"         then cmd_code(Dkit.resolve!, argv.first)
      when "up"           then cmd_up(argv)
      when "down"         then cmd_down(argv)
      when "logs"         then cmd_logs(argv)
      when "version", "--version", "-v"
        puts "dkit #{VERSION}"
      when nil, "help", "--help", "-h"
        cmd_help
      else
        warn "dkit: unknown command '#{command}'. Run 'dkit help'."
        exit 1
      end
    end

    def cmd_root
      root = Project.find_root
      root ? puts(root) : exit(1)
    end

    def cmd_init
      root = Project.find_root
      Dkit.abort_err("no #{DC_CONFIG} found — are you inside a devcontainer project?") unless root

      f = Intercept.file_path(root)
      if File.exist?(f)
        puts "dkit: #{f} already exists:"
        puts File.read(f)
        return
      end

      cmds = []
      cmds += %w[rails bundle rspec rubocop rake] if File.exist?(File.join(root, "Gemfile"))
      cmds += %w[yarn node npx]                   if File.exist?(File.join(root, "package.json"))
      cmds = %w[bash]                             if cmds.empty?

      File.write(f, "# verbose: false  # uncomment to suppress routing messages\n" + cmds.join("\n") + "\n")
      puts "dkit: created #{f}"
      puts "Commands: #{cmds.join(", ")}"
      puts "Tip: commit this file to share with your team"
      puts "     git add #{DC_INTERCEPT} && git commit -m 'chore: add dkit intercept config'"
    end

    def cmd_hook
      puts ShellHook.generate
    end

    def cmd_intercept(argv)
      root = Project.find_root
      Dkit.abort_err("no #{DC_CONFIG} found — are you inside a devcontainer project?") unless root

      sub = argv.shift&.downcase
      case sub
      when "list"
        list = Intercept.list(root)
        f    = Intercept.file_path(root)
        if list.empty?
          puts "No intercept file found. Run: dkit init"
        else
          puts "Intercepted commands (#{f}):"
          list.each { |c| puts "  #{c}" }
        end
        puts "\nSpecial (always active): #{SPECIAL_COMMANDS.join(", ")}"
      when "add"
        Dkit.abort_err("intercept add: command name required") if argv.empty?
        Intercept.add(root, argv.first)
      when "remove"
        Dkit.abort_err("intercept remove: command name required") if argv.empty?
        Intercept.remove(root, argv.first)
      else
        Dkit.abort_err("intercept: unknown subcommand '#{sub}'. Use: list, add, remove")
      end
    end

    def cmd_exec(ctx, args)
      Dkit.abort_err("exec: no command given") if args.empty?
      warn "\e[32m[dkit] #{args.join(" ")} → #{ctx.container}\e[0m" if Intercept.verbose_enabled?(ctx.project_root)
      system("docker", "exec", "--user", ctx.user, "--workdir", ctx.cwd, ctx.container, *args)
      exit $?.exitstatus
    end

    def cmd_run(ctx, args)
      Dkit.abort_err("run: no command given") if args.empty?
      warn "\e[32m[dkit] #{args.join(" ")} → #{ctx.container}\e[0m" if Intercept.verbose_enabled?(ctx.project_root)
      exec("docker", "exec", "-it", "--user", ctx.user, "--workdir", ctx.cwd, ctx.container, *args)
    end

    def cmd_shell(ctx)
      system("docker", "exec", "-it", "--user", ctx.user, "--workdir", ctx.cwd, ctx.container, "zsh", "-l")
    end

    def cmd_claude(ctx, args)
      warn "\e[32m[dkit] claude → #{ctx.container}\e[0m" if Intercept.verbose_enabled?(ctx.project_root)
      exec("docker", "exec", "-it", "--user", ctx.user, "--workdir", ctx.cwd, ctx.container, "claude", *args)
    end

    def cmd_code(ctx, path_arg)
      warn "\e[32m[dkit] code → #{ctx.container}\e[0m" if Intercept.verbose_enabled?(ctx.project_root)
      host_path = path_arg ? File.expand_path(path_arg) : ctx.project_root
      rel = begin
        Pathname(host_path).relative_path_from(Pathname(ctx.project_root)).to_s
      rescue ArgumentError
        "."
      end
      container_path = (rel == ".") ? ctx.workspace : File.join(ctx.workspace, rel)

      payload = JSON.generate({ "hostPath" => ctx.project_root })
      hex     = payload.unpack1("H*")
      uri     = "vscode-remote://dev-container+#{hex}#{container_path}"

      if system("which code > /dev/null 2>&1")
        exec("code", "--folder-uri", uri)
      elsif system("which devcontainer > /dev/null 2>&1")
        exec("devcontainer", "open", ctx.project_root)
      else
        Dkit.abort_err("'code' CLI not found. In VS Code: Shell Command: Install 'code' command in PATH")
      end
    end

    def cmd_status_dispatch(argv)
      quiet = argv.include?("--quiet")
      ctx   = Dkit.resolve!(quiet: quiet)
      cmd_status(ctx, quiet: quiet)
    end

    def cmd_status(ctx, quiet:)
      return if quiet
      puts "Project root  : #{ctx.project_root}"
      puts "Container     : #{ctx.container} (running)"
      puts "Remote user   : #{ctx.user}"
      puts "Workspace     : #{ctx.workspace}"
      puts "Exec CWD      : #{ctx.cwd}"
      puts "Compose files : #{ctx.compose_files.join(", ")}"
      f = Intercept.file_path(ctx.project_root)
      if File.exist?(f)
        puts "Intercept     : #{Intercept.list(ctx.project_root).join(", ")}"
      else
        puts "Intercept     : (none — run 'dkit init')"
      end
    end

    def cmd_compose(ctx, args)
      files_flags = ctx.compose_files.flat_map { |f| ["-f", f] }
      exec("docker", "compose", *files_flags, *args)
    end

    def cmd_up(argv)
      ctx = Dkit.resolve!(quiet: true) rescue nil
      if ctx
        cmd_compose(ctx, ["up", "-d", *argv])
      else
        exec("docker", "compose", "up", "-d", *argv)
      end
    end

    def cmd_down(argv)
      ctx = Dkit.resolve!
      cmd_compose(ctx, ["down", *argv])
    end

    def cmd_logs(argv)
      ctx = Dkit.resolve!
      cmd_compose(ctx, ["logs", "-f", *argv])
    end

    def cmd_help
      puts <<~HELP
        dkit #{VERSION} — DevKit: routes commands into your devcontainer

        Usage:
          dkit exec <cmd> [args]          Run command without TTY (scripting)
          dkit run  <cmd> [args]          Run command interactively (TTY)
          dkit shell                      Open interactive shell (zsh) in container
          dkit code  [path]               Open VS Code attached to devcontainer
          dkit claude [args]              Run claude in container (interactive)

          dkit status                     Show resolved devcontainer context
          dkit status --quiet             Exit 0 if container running, 1 otherwise
          dkit root                       Print project root (no docker needed)

          dkit up    [service]            docker compose up -d
          dkit down  [flags]              docker compose down
          dkit logs  [service]            docker compose logs -f

          dkit init                       Create .devcontainer/dkit-intercept with auto-detected defaults
          dkit intercept list             List intercepted commands for current project
          dkit intercept add <cmd>        Add command to current project's intercept list
          dkit intercept add 'bin/*'      Add glob pattern (quote to prevent shell expansion)
          dkit intercept remove <cmd>     Remove command from current project's intercept list

        Verbose routing messages (on by default):
          Add 'verbose: false' to .devcontainer/dkit-intercept  (per project, committed)
          Export DKIT_VERBOSE=0                                  (personal override)

          dkit hook                       Emit shell hook code for ~/.zshrc
          dkit version                    Print version
          dkit help                       Show this help

        Shell integration (add to ~/.zshrc):
          eval "$(dkit hook)"

        Project setup:
          cd ~/projects/my-app
          dkit init                       # creates .devcontainer/dkit-intercept
          git add .devcontainer/dkit-intercept && git commit -m "chore: add dkit config"

        Adding a new command to a project:
          dkit intercept add terraform
          exec zsh
      HELP
    end
  end
end
