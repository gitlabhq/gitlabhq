# frozen_string_literal: true

module BundlerChecksum::Command
  module Lint
    extend self

    def execute
      definition = Bundler.definition
      definition.validate_runtime!
      definition.resolve_only_locally!

      errors = lint_specs(definition.specs.sort_by(&:name))
      show_errors(errors)

      !errors.any?
    end

    private

    def lint_specs(specs)
      specs.filter_map do |spec|
        next unless spec.source.is_a?(Bundler::Source::Rubygems)
        next if default_gem_without_cache_file?(spec)

        lint_spec(spec)
      end
    end

    def lint_spec(spec)
      expected_checksum = expected_checksum_for(spec)

      if expected_checksum
        actual_checksum = actual_checksum_for(spec)

        if expected_checksum != actual_checksum
          <<~ERROR
            #{error_message_for(spec, 'Invalid checksum')}

            Expected: #{expected_checksum}
              Actual: #{actual_checksum}
          ERROR
        end
      else
        error_message_for(spec, 'Missing checksum')
      end
    end

    def error_message_for(spec, message)
      "ERROR: #{message} for gem `#{spec.name}` (#{spec.version} #{spec.platform})"
    end

    def show_errors(errors)
      return if errors.none?

      errors.each { |error| $stderr.puts error }

      $stderr.puts <<~MSG

        Please run `bundle exec bundler-checksum init` to add correct checksums.
      MSG
    end

    def default_gem_without_cache_file?(spec)
      spec.default_gem? && !File.exist?(spec.cache_file)
    end

    def expected_checksum_for(spec)
      info_list = gems_with_checksums.fetch(spec.name, [])

      info = info_list.find do |hash|
        hash[:version] == spec.version.to_s &&
          hash[:platform] == spec.platform.to_s
      end

      info&.fetch(:checksum)
    end

    def actual_checksum_for(spec)
      path = spec.cache_file

      Bundler::SharedHelpers.filesystem_access(path, :read) do
        Bundler::SharedHelpers.digest(:SHA256).hexdigest(File.read(path))
      end
    end

    def gems_with_checksums
      @gems_with_checksums ||= local_checksums.group_by { |hash| hash[:name] }
    end

    def local_checksums
      ::BundlerChecksum.checksums_from_file
    end
  end
end
