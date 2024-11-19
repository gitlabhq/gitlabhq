# frozen_string_literal: true

module Tooling
  module Danger
    class OutdatedTodo
      TODOS_GLOBS = %w[
        .rubocop_todo/**/*.yml
        spec/support/rspec_order_todo.yml
      ].freeze

      def initialize(filenames, context:, todos: TODOS_GLOBS, allow_fail: false)
        @filenames = filenames
        @context = context
        @todos_globs = todos
        @allow_fail = allow_fail
      end

      def check
        filenames.each do |filename|
          check_filename(filename)
        end
      end

      private

      attr_reader :filenames, :context, :allow_fail

      def check_filename(filename)
        mentions = all_mentions_for(filename)

        return if mentions.empty?

        message = <<~MESSAGE
          `#{filename}` was removed but is mentioned in:
          #{mentions.join("\n")}
        MESSAGE

        if allow_fail
          context.fail message
        else
          context.warn message
        end
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
          # Negative lookbehind to match the filename which is not preceeded by `ee/`
          .select { |text, _line| %r{.*(?<!ee/)#{filename}.*}.match?(text) }
          .map { |_text, line| "#{todo}:#{line}" }
      end

      def todos
        @todos ||= @todos_globs.flat_map { |value| Dir.glob(value) }
      end
    end
  end
end
