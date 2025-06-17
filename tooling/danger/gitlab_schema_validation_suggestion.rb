# frozen_string_literal: true

require_relative 'suggestion'

module Tooling
  module Danger
    module GitlabSchemaValidationSuggestion
      include ::Tooling::Danger::Suggestor

      MATCH = %r{gitlab_schema: gitlab_main_clusterwide}
      REPLACEMENT = nil
      DB_DOCS_PATH = %r{\Adb/docs/[^/]+\.ya?ml\z}

      SUGGESTION = <<~MESSAGE_MARKDOWN
        :warning: You have added `gitlab_main_clusterwide` (deprecated) as the schema for this table. We expect most tables to use the
        `gitlab_main_cell` schema instead.

        Please see the [guidelines on choosing gitlab schema](https://docs.gitlab.com/ee/development/cells/#what-schema-to-choose-if-the-feature-can-be-cluster-wide) for more information.

        Please consult with `@gitlab-com/gl-infra/tenant-scale/cells-infrastructure` if you believe that the clusterwide schema is the best fit for this table.
      MESSAGE_MARKDOWN

      def add_suggestions_on_using_clusterwide_schema
        helper.all_changed_files.grep(DB_DOCS_PATH).each do |filename|
          add_suggestion(
            filename: filename,
            regex: MATCH,
            replacement: REPLACEMENT,
            comment_text: SUGGESTION
          )
        end
      end
    end
  end
end
