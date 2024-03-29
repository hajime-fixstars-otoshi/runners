module Runners
  class Changes
    attr_reader :changed_paths
    attr_reader :unchanged_paths
    attr_reader :untracked_paths
    attr_reader :patches

    def initialize(changed_paths:, unchanged_paths:, untracked_paths:, patches:)
      @changed_paths = changed_paths
      @unchanged_paths = unchanged_paths
      @untracked_paths = untracked_paths
      @patches = patches
    end

    def delete_unchanged(dir:, except: [], only: [])
      # @type var files_to_delete: Array<Pathname>
      files_to_delete = []

      unchanged_paths.each do |path|
        if only.empty? || only.any? {|pattern| File.fnmatch(pattern, path.to_s, File::FNM_DOTMATCH) }
          if except.none? {|pattern| File.fnmatch(pattern, path.to_s, File::FNM_DOTMATCH) }
            file = dir + path
            if file.file?
              files_to_delete << dir + path
              yield(dir + path) if block_given?
            end
          end
        end
      end

      FileUtils.rm(files_to_delete.map(&:to_s))
    end

    def include?(issue)
      gdp = patches # NOTE: This assignment is required for typecheck by Steep
      if gdp
        location = issue.location
        return true unless location
        patch = gdp.find_patch_by_file(issue.path.to_s)
        if patch && location
          patch.changed_lines.one? { |line| location.start_line == line.number }
        else
          false
        end
      else
        Set.new(changed_paths).member?(issue.path)
      end
    end

    def self.calculate(base_dir:, head_dir:, working_dir:, patches:)
      changed_paths = []
      unchanged_paths = []
      untracked_paths = []

      Pathname.glob(working_dir + "**/*", File::FNM_DOTMATCH).each do |working_path|
        next unless working_path.file?

        relative_path = working_path.relative_path_from(working_dir)
        head_path = head_dir + relative_path
        base_path = base_dir + relative_path

        working_digest = Digest::SHA1.new.file(working_path.to_s)
        if head_path.file?
          head_digest = Digest::SHA1.new.file(head_path.to_s)

          if head_digest == working_digest
            if base_path.file?
              base_digest = Digest::SHA1.new.file(base_path.to_s)

              if head_digest == base_digest
                unchanged_paths << relative_path
              else
                changed_paths << relative_path
              end
            else
              changed_paths << relative_path
            end
          else
            untracked_paths << relative_path
          end
        else
          untracked_paths << relative_path
        end
      end

      new(changed_paths: changed_paths.sort!,
          unchanged_paths: unchanged_paths.sort!,
          untracked_paths: untracked_paths.sort!,
          patches: patches)
    end
  end
end
