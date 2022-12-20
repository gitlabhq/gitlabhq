# frozen_string_literal: true

module Tooling
  module Danger
    module UserTypes
      FILE_PATH = "app/models/concerns/has_user_type.rb"
      BOT_USER_TYPES_CHANGE_INDICATOR_REGEX = %r{BOT_USER_TYPES}.freeze
      BOT_USER_TYPES_CHANGED_WARNING = <<~MSG
        You are changing BOT_USER_TYPES in `app/models/concerns/has_user_type.rb`.
        If you are adding or removing new bots, remember to update the `active_billable_users` index with the new value.
        If the bot is not billable, remember to make sure that it's not counted as a billable user.
      MSG

      def bot_user_types_change_warning
        return unless impacted?

        warn BOT_USER_TYPES_CHANGED_WARNING if bot_user_types_impacted?
      end

      private

      def impacted?
        helper.modified_files.include?(FILE_PATH)
      end

      def bot_user_types_impacted?
        helper.changed_lines(FILE_PATH).any? { |change| change =~ BOT_USER_TYPES_CHANGE_INDICATOR_REGEX }
      end
    end
  end
end
