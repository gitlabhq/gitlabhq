# frozen_string_literal: true

require 'yaml'

module Tooling
  class FindCodeowners
    def execute
      load_definitions.each do |section, group_defintions|
        puts section

        group_defintions.each do |group, list|
          print_entries(group, list[:entries]) if list[:entries]
          print_expanded_entries(group, list) if list[:allow]

          puts
        end
      end
    end

    def load_definitions
      result = load_config

      result.each do |section, group_defintions|
        group_defintions.each do |group, definitions|
          definitions.transform_values! do |rules|
            case rules
            when Hash
              case rules[:keywords]
              when Array
                rules[:keywords].flat_map do |keyword|
                  rules[:patterns].map do |pattern|
                    pattern % { keyword: keyword }
                  end
                end
              else
                rules[:patterns]
              end
            when Array
              rules
            end
          end
        end
      end

      result
    end

    def load_config
      config_path = "#{__dir__}/../../config/CODEOWNERS.yml"

      YAML.safe_load_file(config_path, symbolize_names: true)
    end

    # Copied and modified from ee/lib/gitlab/code_owners/file.rb
    def path_matches?(pattern, path)
      # `FNM_DOTMATCH` makes sure we also match files starting with a `.`
      # `FNM_PATHNAME` makes sure ** matches path separators
      flags = ::File::FNM_DOTMATCH | ::File::FNM_PATHNAME

      # BEGIN extension
      flags |= ::File::FNM_EXTGLOB
      # END extension

      ::File.fnmatch?(normalize_pattern(pattern), path, flags)
    end

    # Copied from ee/lib/gitlab/code_owners/file.rb
    def normalize_pattern(pattern)
      # Remove `\` when escaping `\#`
      pattern = pattern.sub(/\A\\#/, '#')
      # Replace all whitespace preceded by a \ with a regular whitespace
      pattern = pattern.gsub(/\\\s+/, ' ')

      return '/**/*' if pattern == '*'

      unless pattern.start_with?('/')
        pattern = "/**/#{pattern}"
      end

      if pattern.end_with?('/')
        pattern = "#{pattern}**/*"
      end

      pattern
    end

    def consolidate_paths(matched_files)
      matched_files.group_by { |file| File.dirname(file) }.flat_map do |dir, files|
        # First line is the dir itself
        if find_dir_maxdepth_1(dir).lines.drop(1).sort == files.sort
          "#{dir}\n"
        else
          files
        end
      end.sort
    end

    private

    def print_entries(group, entries)
      entries.each do |entry|
        puts "#{entry} #{group}"
      end
    end

    def print_expanded_entries(group, list)
      matched_files = git_ls_files.each_line.select do |line|
        list[:allow].find do |pattern|
          path = "/#{line.chomp}"

          path_matches?(pattern, path) &&
            (
              list[:deny].nil? ||
              list[:deny].none? { |pattern| path_matches?(pattern, path) }
            )
        end
      end

      consolidated = consolidate_paths(matched_files)
      consolidated_again = consolidate_paths(consolidated)

      # Consider the directory structure is a tree structure:
      # https://en.wikipedia.org/wiki/Tree_(data_structure)
      # After we consolidated the leaf entries, it could be possible that
      # we can consolidate further for the new leaves. Repeat this
      # process until we see no improvements.
      while consolidated_again.size < consolidated.size
        consolidated = consolidated_again
        consolidated_again = consolidate_paths(consolidated)
      end

      consolidated.each do |line|
        path = line.chomp

        if File.directory?(path)
          puts "/#{path}/ #{group}"
        else
          puts "/#{path} #{group}"
        end
      end
    end

    def find_dir_maxdepth_1(dir)
      `find #{dir} -maxdepth 1`
    end

    def git_ls_files
      @git_ls_files ||= `git ls-files`
    end
  end
end
