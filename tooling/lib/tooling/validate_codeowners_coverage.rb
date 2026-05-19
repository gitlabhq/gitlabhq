# frozen_string_literal: true

require 'yaml'

module Tooling
  class ValidateCodeownersCoverage
    DEFAULT_CODEOWNERS_PATH = '.gitlab/CODEOWNERS'
    DEFAULT_CONFIG_PATH = File.expand_path('../../config/validate_codeowners_coverage.yml', __dir__)

    def initialize(codeowners_path: DEFAULT_CODEOWNERS_PATH, config_path: DEFAULT_CONFIG_PATH)
      @codeowners_path = codeowners_path
      @config_path = config_path
    end

    def missing_coverage
      dirs = top_level_directories - load_exclusions
      dirs.reject { |dir| directory_has_explicit_entry?(dir) }
    end

    def covered_exclusions
      load_exclusions.select { |dir| directory_has_explicit_entry?(dir) }
    end

    private

    def top_level_directories
      git_ls_tree.each_line.map(&:chomp).sort
    end

    def load_exclusions
      @load_exclusions ||= begin
        config = YAML.safe_load_file(@config_path, symbolize_names: false)
        config['excluded_directories'] || []
      end
    end

    def directory_has_explicit_entry?(dirname)
      codeowners_lines.any? { |line| line.split.first == "/#{dirname}/" }
    end

    def codeowners_lines
      @codeowners_lines ||= File.readlines(@codeowners_path, chomp: true).reject do |line|
        line.empty? ||
          line.start_with?('#') ||
          line.start_with?('*') ||
          line.start_with?('!') ||
          line.match?(/\A\^?\[/)
      end
    end

    def git_ls_tree
      @git_ls_tree ||= IO.popen(%w[git ls-tree --name-only -d HEAD], &:read)
    end
  end
end
