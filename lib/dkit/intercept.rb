require "fileutils"

module Dkit
  module Intercept
    module_function

    def file_path(project_root)
      File.join(project_root, DC_INTERCEPT)
    end

    def list(project_root)
      f = file_path(project_root)
      return [] unless File.exist?(f)
      File.readlines(f, chomp: true)
          .reject { |l| l.strip.empty? || l.strip.start_with?("#") }
          .map(&:strip)
          .uniq
    end

    def add(project_root, cmd)
      current = list(project_root)
      if current.include?(cmd)
        puts "dkit: '#{cmd}' is already in the intercept list"
        return
      end
      File.open(file_path(project_root), "a") { |f| f.puts cmd }
      puts "dkit: added '#{cmd}' — reload shell to activate (exec zsh)"
    end

    def remove(project_root, cmd)
      f = file_path(project_root)
      unless list(project_root).include?(cmd)
        puts "dkit: '#{cmd}' is not in the intercept list"
        return
      end
      lines = File.readlines(f).reject { |l| l.strip == cmd }
      File.write(f, lines.join)
      puts "dkit: removed '#{cmd}' — reload shell to deactivate (exec zsh)"
    end

    def verbose_enabled?(project_root)
      return false if ENV["DKIT_VERBOSE"] == "0"
      f = file_path(project_root)
      return true unless File.exist?(f)
      !File.readlines(f, chomp: true).any? { |l| l.strip == "verbose: false" }
    end
  end
end
