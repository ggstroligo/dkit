module Dkit
  Context = Struct.new(:project_root, :container, :user, :workspace, :cwd, :compose_files, keyword_init: true)

  module_function

  def abort_err(msg)
    warn "dkit: #{msg}"
    exit 1
  end

  def resolve!(quiet: false)
    root = Project.find_root
    unless root
      quiet ? exit(1) : abort_err("no #{DC_CONFIG} found in #{Dir.pwd} or any parent directory")
    end

    cfg       = Container.load_dc_config(root)
    service   = cfg["service"]          || "app"
    workspace = cfg["workspaceFolder"]  || "/workspace"
    user      = cfg["remoteUser"]       || "root"

    container = Container.resolve_name(root, cfg)
    unless container
      quiet ? exit(1) : abort_err("could not determine container name for service '#{service}'")
    end

    unless Container.running?(container)
      quiet ? exit(1) : abort_err("container '#{container}' is not running. Try: dkit up")
    end

    compose_files = Array(cfg["dockerComposeFile"]).map do |f|
      File.expand_path(f, File.join(root, ".devcontainer"))
    end

    Context.new(
      project_root:  root,
      container:     container,
      user:          user,
      workspace:     workspace,
      cwd:           Container.cwd(root, workspace),
      compose_files: compose_files
    )
  end
end
