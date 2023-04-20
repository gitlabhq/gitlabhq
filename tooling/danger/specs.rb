# frozen_string_literal: true

Dir[File.expand_path('specs/*_suggestion.rb', __dir__)].each { |file| require file }

module Tooling
  module Danger
    module Specs
      SPEC_FILES_REGEX = 'spec/'
      EE_PREFIX = 'ee/'

      SUGGESTIONS = [
        FeatureCategorySuggestion,
        MatchWithArraySuggestion,
        ProjectFactorySuggestion
      ].freeze

      def changed_specs_files(ee: :include)
        changed_files = helper.all_changed_files
        folder_prefix =
          case ee
          when :include
            "(#{EE_PREFIX})?"
          when :only
            EE_PREFIX
          when :exclude
            nil
          end

        changed_files.grep(%r{\A#{folder_prefix}#{SPEC_FILES_REGEX}})
      end

      def add_suggestions_for(filename)
        SUGGESTIONS.each do |suggestion|
          suggestion.new(filename, context: self).suggest
        end
      end
    end
  end
end
