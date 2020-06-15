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
      impacted_tests = ee_impact | non_ee_impact
      impacted_tests.impact(@file)
    end

    private

    attr_reader :file, :foss_test_only, :result

    class ImpactedTestFile
      attr_reader :pattern_matchers

      def initialize
        @pattern_matchers = {}

        yield self if block_given?
      end

      def associate(pattern, &block)
        @pattern_matchers[pattern] = block
      end

      def impact(file)
        @pattern_matchers.each_with_object(Set.new) do |(pattern, block), result|
          if (match = pattern.match(file))
            result << block.call(match)
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
      ImpactedTestFile.new do |impact|
        unless foss_test_only
          impact.associate(%r{^#{EE_PREFIX}app/(.+)\.rb$}) { |match| "#{EE_PREFIX}spec/#{match[1]}_spec.rb" }
          impact.associate(%r{^#{EE_PREFIX}app/(.*/)ee/(.+)\.rb$}) { |match| "#{EE_PREFIX}spec/#{match[1]}#{match[2]}_spec.rb" }
          impact.associate(%r{^#{EE_PREFIX}lib/(.+)\.rb$}) { |match| "#{EE_PREFIX}spec/lib/#{match[1]}_spec.rb" }
          impact.associate(%r{^#{EE_PREFIX}spec/(.+)_spec.rb$}) { |match| match[0] }
        end

        impact.associate(%r{^#{EE_PREFIX}(?!spec)(.*/)ee/(.+)\.rb$}) { |match| "spec/#{match[1]}#{match[2]}_spec.rb" }
        impact.associate(%r{^#{EE_PREFIX}spec/(.*/)ee/(.+)\.rb$}) { |match| "spec/#{match[1]}#{match[2]}.rb" }
      end
    end

    def non_ee_impact
      ImpactedTestFile.new do |impact|
        impact.associate(%r{^app/(.+)\.rb$}) { |match| "spec/#{match[1]}_spec.rb" }
        impact.associate(%r{^(tooling/)?lib/(.+)\.rb$}) { |match| "spec/#{match[1]}lib/#{match[2]}_spec.rb" }
        impact.associate(%r{^spec/(.+)_spec.rb$}) { |match| match[0] }
      end
    end
  end
end
