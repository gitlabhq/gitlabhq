# frozen_string_literal: true

require 'set'

module BundlerChecksum::Command
  module Lint
    extend self

    def execute
      linted = true

      Bundler.definition.resolve.sort_by(&:name).each do |spec|
        next unless spec.source.is_a?(Bundler::Source::Rubygems)

        unless checksum_for?(spec.name)
          $stderr.puts "ERROR: Missing checksum for gem `#{spec.name}`"
          linted = false
        end
      end

      unless linted
        $stderr.puts <<~MSG

          Please run `bundle exec bundler-checksum init` to add missing checksums.
        MSG
      end

      linted
    end

    private

    def checksum_for?(name)
      gems_with_checksums.include?(name)
    end

    def gems_with_checksums
      @gems_with_checksums ||= local_checksums.map { |hash| hash[:name] }.to_set
    end

    def local_checksums
      ::BundlerChecksum.checksums_from_file
    end
  end
end
