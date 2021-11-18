# frozen_string_literal: true
require 'erb'

module Deprecations
  module Docs
    module_function

    def path
      Rails.root.join("doc/update/deprecations.md")
    end

    def render
      deprecations_yaml_glob = Rails.root.join("data/deprecations/**/*.yml")

      source_files = Rake::FileList.new(deprecations_yaml_glob) do |fl|
        fl.exclude(/example\.yml$/)
      end

      deprecations = source_files.flat_map do |file|
        YAML.load_file(file)
      end

      deps = VersionSorter.sort(deprecations) { |d| d["removal_milestone"] }

      deprecations = deps.sort_by { |d| d["name"] }

      milestones = deps.map { |d| d["removal_milestone"] }.uniq

      template = Rails.root.join("data/deprecations/templates/_deprecation_template.md.erb")

      load_template(template)
        .result_with_hash(deprecations: deprecations, milestones: milestones)
    end

    def load_template(filename)
      ERB.new(File.read(filename), trim_mode: '-')
    end
  end
end
