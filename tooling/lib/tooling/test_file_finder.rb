# frozen_string_literal: true

require 'set'

module Tooling
  class TestFileFinder
    EE_PREFIX = 'ee/'

    def initialize(file, foss_test_only: false)
      @file = file
      @foss_test_only = foss_test_only
    end

    def test_files
      impacted_tests = ee_impact | non_ee_impact | either_impact
      impacted_tests.impact(@file)
    end

    private

    attr_reader :file, :foss_test_only, :result

    class ImpactedTestFile
      attr_reader :pattern_matchers

      def initialize(prefix: nil)
        @pattern_matchers = {}
        @prefix = prefix

        yield self if block_given?
      end

      def associate(pattern, &block)
        @pattern_matchers[%r{^#{@prefix}#{pattern}}] = block
      end

      def impact(file)
        @pattern_matchers.each_with_object(Set.new) do |(pattern, block), result|
          if (match = pattern.match(file))
            test_files = block.call(match)
            result.merge(Array(test_files))
          end
        end.to_a
      end

      def |(other)
        self.class.new do |combined_matcher|
          self.pattern_matchers.each do |pattern, block|
            combined_matcher.associate(pattern, &block)
          end
          other.pattern_matchers.each do |pattern, block|
            combined_matcher.associate(pattern, &block)
          end
        end
      end
    end

    def ee_impact
      ImpactedTestFile.new(prefix: EE_PREFIX) do |impact|
        unless foss_test_only
          impact.associate(%r{app/(.+)\.rb$}) { |match| "#{EE_PREFIX}spec/#{match[1]}_spec.rb" }
          impact.associate(%r{app/(.*/)ee/(.+)\.rb$}) { |match| "#{EE_PREFIX}spec/#{match[1]}#{match[2]}_spec.rb" }
          impact.associate(%r{lib/(.+)\.rb$}) { |match| "#{EE_PREFIX}spec/lib/#{match[1]}_spec.rb" }
        end

        impact.associate(%r{(?!spec)(.*/)ee/(.+)\.rb$}) { |match| "spec/#{match[1]}#{match[2]}_spec.rb" }
        impact.associate(%r{spec/(.*/)ee/(.+)\.rb$}) { |match| "spec/#{match[1]}#{match[2]}.rb" }
      end
    end

    def non_ee_impact
      ImpactedTestFile.new do |impact|
        impact.associate(%r{app/(.+)\.rb$}) { |match| "spec/#{match[1]}_spec.rb" }
        impact.associate(%r{(tooling/)?lib/(.+)\.rb$}) { |match| "spec/#{match[1]}lib/#{match[2]}_spec.rb" }
        impact.associate(%r{config/initializers/(.+)\.rb$}) { |match| "spec/initializers/#{match[1]}_spec.rb" }
        impact.associate('db/structure.sql') { 'spec/db/schema_spec.rb' }
        impact.associate(%r{db/(?:post_)?migrate/([0-9]+)_(.+)\.rb$}) do |match|
          [
            "spec/migrations/#{match[2]}_spec.rb",
            "spec/migrations/#{match[1]}_#{match[2]}_spec.rb"
          ]
        end
      end
    end

    def either_impact
      ImpactedTestFile.new(prefix: %r{^(?<prefix>#{EE_PREFIX})?}) do |impact|
        impact.associate(%r{app/views/(?<view>.+)\.haml$}) { |match| "#{match[:prefix]}spec/views/#{match[:view]}.haml_spec.rb" }
        impact.associate(%r{spec/(.+)_spec\.rb$}) { |match| match[0] }
        impact.associate(%r{spec/factories/.+\.rb$}) { 'spec/factories_spec.rb' }
      end
    end
  end
end
