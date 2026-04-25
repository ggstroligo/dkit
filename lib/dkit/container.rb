require "json"
require "yaml"
require "shellwords"

module Dkit
  module Container
    module_function

    def docker(*args, capture: false)
      cmd = ["docker", *args]
      if capture
        out = `#{cmd.map(&:shellescape).join(" ")} 2>/dev/null`.strip
        out.empty? ? nil : out
      else
        system(*cmd)
      end
    end

    def load_dc_config(project_root)
      raw = File.read(File.join(project_root, DC_CONFIG))
      raw = raw.gsub(%r{/\*.*?\*/}m, "").gsub(%r{//[^\n]*}, "")
      JSON.parse(raw)
    end

    def resolve_name(project_root, cfg)
      service       = cfg["service"]
      compose_files = Array(cfg["dockerComposeFile"]).map do |f|
        File.expand_path(f, File.join(project_root, ".devcontainer"))
      end

      # Strategy A: container_name from compose YAML
      compose_files.each do |cf|
        next unless File.exist?(cf)
        data = YAML.safe_load(File.read(cf))
        name = data.dig("services", service, "container_name")
        return name if name
      end

      # Strategy B: docker label query
      project_name = File.basename(project_root).downcase.gsub(/[^a-z0-9]/, "")
      name = docker("ps",
        "--filter", "label=com.docker.compose.service=#{service}",
        "--filter", "label=com.docker.compose.project=#{project_name}",
        "--format", "{{.Names}}",
        capture: true
      )
      return name if name

      # Strategy C: docker compose ps -q
      first_file = compose_files.first
      if first_file && File.exist?(first_file)
        id = docker("compose", "-f", first_file, "ps", "-q", service, capture: true)
        return id if id
      end

      nil
    end

    def running?(name)
      status = docker("inspect", "--format", "{{.State.Status}}", name, capture: true)
      status == "running"
    end

    def cwd(project_root, workspace)
      rel = Pathname.new(Dir.pwd).relative_path_from(Pathname.new(project_root)).to_s
      rel.start_with?("..") ? workspace : File.join(workspace, rel)
    rescue ArgumentError
      workspace
    end
  end
end
