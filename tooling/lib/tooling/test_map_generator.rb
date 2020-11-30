# frozen_string_literal: true

require 'set'
require 'yaml'

module Tooling
  class TestMapGenerator
    def initialize
      @mapping = Hash.new { |h, k| h[k] = Set.new }
    end

    def parse(yaml_files)
      Array(yaml_files).each do |yaml_file|
        data = File.read(yaml_file)
        _metadata, example_groups = data.split("---\n").reject(&:empty?).map { |yml| YAML.safe_load(yml, [Symbol]) }

        example_groups.each do |example_id, files|
          files.each do |file|
            spec_file = strip_example_uid(example_id)
            @mapping[file] << spec_file.delete_prefix('./')
          end
        end
      end
    end

    def mapping
      @mapping.transform_values { |set| set.to_a }
    end

    private

    def strip_example_uid(example_id)
      example_id.gsub(/\[.+\]/, '')
    end
  end
end
