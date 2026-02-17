# frozen_string_literal: true

require 'parser/current'
require_relative 'suggestion'

module Tooling
  module Danger
    class IndexRemoval < Suggestion
      INDEX_REMOVAL_METHODS = 'remove_concurrent_index_by_name|remove_concurrent_index|remove_index'
      DROP_INDEX_SQL = 'DROP\s+INDEX(\s+CONCURRENTLY)?(\s+IF\s+EXISTS)?'

      MATCH = %r{\A\+(?!\s*#).*?(#{INDEX_REMOVAL_METHODS}|#{DROP_INDEX_SQL})}i
      REPLACEMENT = nil
      ONCE_PER_FILE = true

      DOCUMENTATION_LINK = 'https://docs.gitlab.com/development/database/adding_database_indexes/#investigating-index-usage'
      DUPLICATE_INDEXES_PATH = 'spec/support/helpers/database/duplicate_indexes.yml'

      SUGGESTION = <<~MESSAGE_MARKDOWN.freeze
        ⚠️ **Index Removal Detected**

        This migration removes a database index. Before merging, please verify:

        1. **Check index usage** via `pg_stat_user_indexes` to confirm the index is unused
        2. **Review the query patterns** that may rely on this index
        3. **Consider if this is a redundant index** (covered by another index)

        If this index is listed in [`duplicate_indexes.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/#{DUPLICATE_INDEXES_PATH}),
        it's already identified as redundant and safe to remove.

        For more information, see: [Investigating index usage](#{DOCUMENTATION_LINK})
      MESSAGE_MARKDOWN

      private

      def added_lines_matching(filename, regex)
        changed_lines = helper.changed_lines(filename).grep(/\A\+( )?/).grep(regex)
        return [] if changed_lines.empty?

        file_lines = project_helper.file_lines(filename)
        file_content = file_lines.join("\n")
        up_method_ranges = up_or_change_method_ranges(file_content)

        # Only include lines that are within `up` or `change` methods
        changed_lines.select do |line|
          line_without_prefix = line.delete_prefix('+')
          line_number = find_line_number(file_lines, line_without_prefix)

          line_in_up_method?(up_method_ranges, line_number + 1) if line_number
        end
      end

      def line_in_up_method?(ranges, line_number)
        ranges.any? { |range| range.cover?(line_number) }
      end

      def up_or_change_method_ranges(file_content)
        buffer = Parser::Source::Buffer.new('(source)')
        buffer.source = file_content

        parser = Parser::CurrentRuby.new
        ast = parser.parse(buffer)

        return [] unless ast

        visitor = UpMethodVisitor.new
        visitor.process(ast)
        visitor.method_ranges
      rescue Parser::SyntaxError
        []
      end

      # AST Visitor that finds `def up` and `def change` method ranges
      class UpMethodVisitor < Parser::AST::Processor
        attr_reader :method_ranges

        UP_METHODS = %i[up change].freeze

        def initialize
          @method_ranges = []
        end

        def on_def(node)
          method_name = node.children.first

          if UP_METHODS.include?(method_name)
            loc = node.location
            @method_ranges << (loc.line..loc.last_line)
          end

          super
        end
      end
    end
  end
end
