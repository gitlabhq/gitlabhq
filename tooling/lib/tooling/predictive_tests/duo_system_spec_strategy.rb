# frozen_string_literal: true

require_relative 'duo_test_selector'

module Tooling
  module PredictiveTests
    # Strategy that uses GitLab Duo to predict which system specs to run
    class DuoSystemSpecStrategy
      def initialize(changed_files:, git_diff_content: nil, logger: nil)
        @changed_files = changed_files
        @git_diff_content = git_diff_content
        @logger = logger || Logger.new($stdout, progname: "duo system spec strategy")
        @confident = false
      end

      # Returns array of system spec paths recommended by Duo
      #
      # @return [Array<String>]
      def execute
        return [] unless duo_available?

        logger.info "Running Duo system spec prediction..."

        selector = DuoTestSelector.new(git_diff: @git_diff_content, changed_files: nil, logger: logger)
        result = selector.select_tests

        if result[:confidence] < DuoTestSelector::CONFIDENCE_THRESHOLD
          logger.warn "Duo returned low confidence (#{result[:confidence]}): #{result[:reasoning]}"
          logger.warn "Skipping Duo predictions, will use fallback strategies"
          @confident = false
          return []
        end

        @confident = true
        specs = result[:specs] || []
        logger.info "Duo recommended #{specs.length} system specs (confidence: #{result[:confidence]})"
        logger.debug "Duo specs: #{specs.join(', ')}"

        specs
      rescue StandardError => e
        logger.error "Duo strategy failed: #{e.class} - #{e.message}"
        logger.debug e.backtrace.join("\n")
        @confident = false
        []
      end

      # Whether Duo made a confident prediction
      # @confident will be false when duo fails, thresholds are crossed, or Duo is not confident in its selections
      #
      # @return [Boolean]
      def confident?
        @confident
      end

      private

      attr_reader :changed_files, :logger, :git_diff_content

      def duo_available?
        return @duo_available if defined?(@duo_available)

        @duo_available = system('which duo > /dev/null 2>&1')
      end
    end
  end
end
