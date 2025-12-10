# frozen_string_literal: true

require 'parser/current'
require_relative 'suggestion'

module Tooling
  module Danger
    class BulkDatabaseActions < Suggestion
      MATCH = %r{\A\+\s+((\S*\.)?((bulk_)?(insert|update|upsert|delete|destroy)(_all)?)|scope\s+:)\b}
      SCOPE_BODY_MATCH = %r{\A\+\s*\.}

      REPLACEMENT = nil
      DOCUMENTATION_LINK = 'https://docs.gitlab.com/development/database_review/#preparation-when-using-bulk-update-operations'
      FIND_SQL_DOCUMENTATION_LINK = 'https://docs.gitlab.com/development/database_review/#tips-for-finding-the-sql-executed-by-the-application'

      SUGGESTION = <<~MESSAGE_MARKDOWN.freeze
        When using any of these:
          - Commands: `insert`, `update`, `upsert`, `delete`, `destroy`
          - Bulk commands: `bulk_insert`, `update_all`, etc.
          - Defining a `scope`

        You must:
          1. Include the **full database query** in the merge request description
             (including scopes, pagination, and limits)
          2. Include the query execution plan
          3. Request a ~database review

        ----

        For more information, see:
        1. [Tips for finding the SQL executed by the application](#{FIND_SQL_DOCUMENTATION_LINK})
        2. [Database Review documentation](#{DOCUMENTATION_LINK})
      MESSAGE_MARKDOWN

      private

      def added_lines_matching(filename, regex)
        changed_lines = helper.changed_lines(filename).grep(/\A\+( )?/)
        file_lines = project_helper.file_lines(filename)
        file_content = file_lines.join("\n")
        scope_ranges = scope_line_ranges_for(file_content)

        changed_lines.select do |line|
          next true if line.match?(regex) # Matches with `MATCH` (insert, update, etc.), include it

          next unless line.match?(SCOPE_BODY_MATCH)

          line_without_prefix = line.delete_prefix('+')
          line_number = find_line_number(file_lines, line_without_prefix)

          line_in_scope?(scope_ranges, line_number + 1) if line_number
        end
      end

      def line_in_scope?(scope_ranges, line_number)
        scope_ranges.any? { |range| range.cover?(line_number) }
      end

      def scope_line_ranges_for(file_content)
        buffer = Parser::Source::Buffer.new('(source)')
        buffer.source = file_content

        parser = Parser::CurrentRuby.new
        ast = parser.parse(buffer)

        return [] unless ast

        visitor = ScopeVisitor.new
        visitor.process(ast)
        visitor.scope_line_ranges
      rescue Parser::SyntaxError
        []
      end

      class ScopeVisitor < Parser::AST::Processor
        attr_reader :scope_line_ranges

        def initialize
          @scope_line_ranges = []
        end

        def on_send(node)
          receiver, method_name, *_args = node.children

          if receiver.nil? && method_name == :scope
            loc = node.location
            @scope_line_ranges << (loc.line..loc.last_line)
          end

          super
        end
      end
    end
  end
end
