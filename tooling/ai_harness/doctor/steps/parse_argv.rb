# frozen_string_literal: true

require_relative '../../../../lib/gitlab/fp/result'
require_relative '../messages'
require_relative 'help_text'

module AiHarness
  module Doctor
    module Steps
      class ParseArgv
        # @param context [Hash] the ROP chain context
        # @return [Gitlab::Fp::Result]
        def self.parse(context)
          if ARGV.include?('--help')
            context[:print_help] = true
            context[:fix] = false
            return Gitlab::Fp::Result.ok(context)
          end

          unknown = ARGV.reject { |arg| arg == '--fix' }
          return invalid_args_result(unknown.first) unless unknown.empty?

          context[:print_help] = false
          context[:fix] = ARGV.include?('--fix')
          Gitlab::Fp::Result.ok(context)
        end

        # @param option [String]
        # @return [Gitlab::Fp::Result]
        def self.invalid_args_result(option)
          Gitlab::Fp::Result.err(
            Messages::InvalidArguments.new(
              {
                stderr_text: "Unknown option: #{option}\n\n#{HelpText.help}",
                exit_code: 1
              }
            )
          )
        end

        private_class_method :invalid_args_result
      end
    end
  end
end
