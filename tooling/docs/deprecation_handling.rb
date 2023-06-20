# frozen_string_literal: true

require 'erb'

module Docs
  class DeprecationHandling
    def initialize(type)
      @type = type
      @yaml_glob_path = Rails.root.join("data/#{type.pluralize}/**/*.yml")
      @template_path = Rails.root.join("data/#{type.pluralize}/templates/_#{type}_template.md.erb")
      @milestone_key_name = "removal_milestone"
    end

    def render
      source_file_paths = Rake::FileList.new(yaml_glob_path) do |fl|
        fl.exclude(/example\.yml$/)
      end

      entries = source_file_paths.flat_map do |file|
        YAML.safe_load_file(file, permitted_classes: [Date])
      end
      entries = entries.sort_by { |d| d["title"] }

      milestones = entries.map { |entry| entry[milestone_key_name] }.uniq
      milestones = VersionSorter.rsort(milestones)

      load_template(template_path)
        .result_with_hash(entries: entries, milestones: milestones)
    end

    private

    def load_template(filename)
      ERB.new(File.read(filename), trim_mode: '-')
    end

    attr_reader :type, :yaml_glob_path, :milestone_key_name, :template_path
  end
end
