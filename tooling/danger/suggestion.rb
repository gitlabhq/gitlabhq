# frozen_string_literal: true

require_relative 'suggestor'

module Tooling
  module Danger
    # A basic suggestion.
    #
    # A subclass needs to define the following constants:
    # * MATCH (Regexp) - A Regexp to match file lines
    # * REPLACEMENT (String) - A suggestion replacement text
    # * SUGGESTION (String) - A suggestion text
    #
    # @see Suggestor
    class Suggestion
      include ::Tooling::Danger::Suggestor

      attr_reader :filename

      def initialize(filename, context:)
        @filename = filename
        @context = context
      end

      def suggest
        add_suggestion(
          filename: filename,
          regex: self.class::MATCH,
          replacement: self.class::REPLACEMENT,
          comment_text: self.class::SUGGESTION
        )
      end

      private

      def helper(...)
        # Previously, we were using `forwardable` but it emitted a mysterious warning:
        #   forwarding to private method Danger::Rubocop#helper
        @context.helper(...)
      end

      def project_helper(...)
        @context.project_helper(...)
      end

      def markdown(...)
        @context.markdown(...)
      end
    end
  end
end
