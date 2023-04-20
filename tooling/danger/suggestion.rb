# frozen_string_literal: true

require 'forwardable'
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
      extend Forwardable
      include ::Tooling::Danger::Suggestor

      def_delegators :@context, :helper, :project_helper, :markdown

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
    end
  end
end
