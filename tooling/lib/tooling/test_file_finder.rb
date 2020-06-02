# frozen_string_literal: true

require 'ostruct'
require 'set'

module Tooling
  class TestFileFinder
    RUBY_EXTENSION = '.rb'
    EE_PREFIX = 'ee/'

    def initialize(file, foss_test_only: false)
      @file = file
      @foss_test_only = foss_test_only
      @result = Set.new
    end

    def test_files
      contexts = [ee_context, foss_context]
      contexts.flat_map do |context|
        match_test_files_for(context)
      end

      result.to_a
    end

    private

    attr_reader :file, :foss_test_only, :result

    def ee_context
      OpenStruct.new.tap do |ee|
        ee.app = %r{^#{EE_PREFIX}app/(.+)\.rb$} unless foss_test_only
        ee.lib = %r{^#{EE_PREFIX}lib/(.+)\.rb$} unless foss_test_only
        ee.spec = %r{^#{EE_PREFIX}spec/(.+)_spec.rb$} unless foss_test_only
        ee.spec_dir = "#{EE_PREFIX}spec" unless foss_test_only
        ee.ee_modules = %r{^#{EE_PREFIX}(?!spec)(.*\/)ee/(.+)\.rb$}
        ee.ee_module_spec = %r{^#{EE_PREFIX}spec/(.*\/)ee/(.+)\.rb$}
        ee.foss_spec_dir = 'spec'
      end
    end

    def foss_context
      OpenStruct.new.tap do |foss|
        foss.app = %r{^app/(.+)\.rb$}
        foss.lib = %r{^lib/(.+)\.rb$}
        foss.tooling = %r{^(tooling/lib/.+)\.rb$}
        foss.spec = %r{^spec/(.+)_spec.rb$}
        foss.spec_dir = 'spec'
      end
    end

    def match_test_files_for(context)
      if (match = context.app&.match(file))
        result << "#{context.spec_dir}/#{match[1]}_spec.rb"
      end

      if (match = context.lib&.match(file))
        result << "#{context.spec_dir}/lib/#{match[1]}_spec.rb"
      end

      if (match = context.tooling&.match(file))
        result << "#{context.spec_dir}/#{match[1]}_spec.rb"
      end

      if context.spec&.match(file)
        result << file
      end

      if (match = context.ee_modules&.match(file))
        result << "#{context.foss_spec_dir}/#{match[1]}#{match[2]}_spec.rb"
      end

      if (match = context.ee_module_spec&.match(file))
        result << "#{context.foss_spec_dir}/#{match[1]}#{match[2]}.rb"
      end
    end
  end
end
