# frozen_string_literal: true

require 'yaml'

module AiHarness
  module Doctor
    module Steps
      module PerformDoctorChecks
        class LoadConfig
          CONFIG_PATH = File.expand_path('../../../config.yml', __dir__).freeze

          # @param context [Hash] the ROP chain context
          # @return [Hash]
          def self.load(context)
            context[:config] = YAML.safe_load_file(CONFIG_PATH)
            context
          end

          private_constant :CONFIG_PATH
        end
      end
    end
  end
end
