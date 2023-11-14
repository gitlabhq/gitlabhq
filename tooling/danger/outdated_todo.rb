# frozen_string_literal: true

module Tooling
  module Danger
    class OutdatedTodo
      TODOS_GLOBS = %w[
        .rubocop_todo/**/*.yml
        spec/support/rspec_order_todo.yml
      ].freeze

      def initialize(filenames, context:, todos: TODOS_GLOBS)
        @filenames = filenames
        @context = context
        @todos_globs = todos
      end

      def check
        filenames.each do |filename|
          check_filename(filename)
        end
      end

      private

      attr_reader :filenames, :context

      def check_filename(filename)
        mentions = all_mentions_for(filename)

        return if mentions.empty?

        context.warn <<~MESSAGE
          `#{filename}` was removed but is mentioned in:
          #{mentions.join("\n")}
        MESSAGE
      end

      def all_mentions_for(filename)
        todos
          .filter_map { |todo| mentioned_lines(filename, todo) }
          .flatten
          .map { |todo| "- `#{todo}`" }
      end

      def mentioned_lines(filename, todo)
        File
          .foreach(todo)
          .with_index(1)
          .select { |text, _line| text.match?(/.*#{filename}.*/) }
          .map { |_text, line| "#{todo}:#{line}" }
      end

      def todos
        @todos ||= @todos_globs.flat_map { |value| Dir.glob(value) }
      end
    end
  end
end
