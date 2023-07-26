# frozen_string_literal: true

require_relative 'suggestor'

module Tooling
  module Danger
    module ModelValidations
      include ::Tooling::Danger::Suggestor

      MODEL_FILES_REGEX = 'app/models'
      EE_PREFIX = 'ee/'
      VALIDATION_METHODS = %w[validates validate validates_each validates_with validates_associated].freeze
      VALIDATIONS_REGEX = /^\+\s*(.*\.)?(#{VALIDATION_METHODS.join('|')})[( ]/

      CODE_QUALITY_URL = "https://docs.gitlab.com/ee/development/code_review.html#quality"
      SUGGEST_MR_COMMENT = <<~SUGGEST_COMMENT.freeze
        Did you consider new validations can break existing records?
        Please follow the [code quality guidelines about new model validations](#{CODE_QUALITY_URL}) when adding a new
        model validation.

        If you're adding the validations to a model with no records you can ignore this warning.
      SUGGEST_COMMENT

      def add_comment_for_added_validations
        changed_model_files.each do |filename|
          add_suggestion(
            filename: filename,
            regex: VALIDATIONS_REGEX,
            comment_text: SUGGEST_MR_COMMENT
          )
        end
      end

      def changed_model_files
        changed_files = helper.all_changed_files
        ee_folder_prefix = "(#{EE_PREFIX})?"

        changed_files.grep(%r{\A#{ee_folder_prefix}#{MODEL_FILES_REGEX}})
      end
    end
  end
end
