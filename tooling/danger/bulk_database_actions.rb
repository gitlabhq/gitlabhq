# frozen_string_literal: true

require_relative 'suggestor'

module Tooling
  module Danger
    module BulkDatabaseActions
      include ::Tooling::Danger::Suggestor

      BULK_UPDATE_METHODS_REGEX = /\.((update|delete|destroy)(_all)?)\b/

      DOCUMENTATION_LINK = 'https://docs.gitlab.com/ee/development/database_review.html#preparation-when-using-update-delete-update_all-and-destroy_all'
      COMMENT_TEXT =
        "When using `update`, `delete`, `update_all`, `delete_all` or `destroy_all` you must include the full " \
        "database query and query execution plan in the merge request description, and request a ~database review. " \
        "This comment can be ignored if the object is not an ActiveRecord class, since no database query " \
        "would be generated. For more information, see [Database Review documentation](#{DOCUMENTATION_LINK}).".freeze

      def add_comment_for_bulk_database_action_method_usage
        changed_ruby_files.each do |filename|
          add_suggestion(
            filename: filename,
            regex: BULK_UPDATE_METHODS_REGEX,
            comment_text: COMMENT_TEXT
          )
        end
      end

      def changed_ruby_files
        helper.added_files.select { |f| f.end_with?('.rb') && !f.start_with?('spec/', 'ee/spec/', 'jh/spec/') }
      end
    end
  end
end
