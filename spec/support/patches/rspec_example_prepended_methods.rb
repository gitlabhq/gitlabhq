# frozen_string_literal: true

module RSpec
  module Core
    module ExamplePrependedMethods
      # Based on https://github.com/rspec/rspec-core/blob/d57c371ee92b16211b80ac7b0b025968438f5297/lib/rspec/core/example.rb#L96-L104,
      # Same as location_rerun_argument but with line number
      def file_path_rerun_argument
        loaded_spec_files = RSpec.configuration.loaded_spec_files

        RSpec::Core::Metadata.ascending(metadata) do |meta|
          break meta[:file_path] if loaded_spec_files.include?(meta[:absolute_file_path])
        end
      end
    end

    module ExampleProcsyPrependedMethods
      def file_path_rerun_argument
        example.file_path_rerun_argument
      end
    end
  end
end

RSpec::Core::Example.prepend(RSpec::Core::ExamplePrependedMethods)
RSpec::Core::Example::Procsy.prepend(RSpec::Core::ExampleProcsyPrependedMethods)
