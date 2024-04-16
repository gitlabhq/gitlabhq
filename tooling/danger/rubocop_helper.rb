# frozen_string_literal: true

module Tooling
  module Danger
    module RubocopHelper
      def execute_inline_disable_suggestor
        # This is noisy for draft MRs, so let's ignore this cop in draft mode since we have
        # rubocop watching this as well.
        return if helper.draft_mr?

        # Danger should not comment when inline disables are added in the following files.
        no_suggestions_for_extensions = %w[.md]

        helper.all_changed_files.each do |filename|
          next if filename.end_with?(*no_suggestions_for_extensions)

          add_inline_disable_suggestions_for(filename)
        end
      end

      def execute_todo_suggestor
        # we'll assume a todo file modification only means regeneration/gem update/etc
        return if contains_rubocop_update_files? || only_rubocop_todo_files?

        rubocop_todo_files(helper.modified_files).each do |filename|
          add_todo_suggestion_for(filename)
        end
      end

      def execute_new_todo_reminder
        return if helper.draft_mr?

        rubocop_todo_files(helper.added_files).each do |filename|
          add_new_rubocop_reminder(filename)
        end
      end

      private

      def contains_rubocop_update_files?
        # this will help be a signal for valid todo file additions or changes
        helper.all_changed_files.any? { |path| path =~ %r{\A(Gemfile(\z|.lock\z)|.rubocop.yml\z)} }
      end

      def only_rubocop_todo_files?
        # this will help be a signal that this is change only has todo files in it
        helper.all_changed_files.none? { |path| path !~ %r{\A\.rubocop_todo/.*/\w+.yml\b} }
      end

      def rubocop_todo_files(files)
        files.grep(%r{\A\.rubocop_todo/.*/\w+.yml\b})
      end

      def add_todo_suggestion_for(filename)
        Tooling::Danger::RubocopDiscourageTodoAddition.new(filename, context: self).suggest
      end

      def add_inline_disable_suggestions_for(filename)
        Tooling::Danger::RubocopInlineDisableSuggestion.new(filename, context: self).suggest
      end

      def add_new_rubocop_reminder(filename)
        Tooling::Danger::RubocopNewTodo.new(filename, context: self).suggest
      end
    end
  end
end
