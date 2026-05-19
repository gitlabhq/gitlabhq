# frozen_string_literal: true

require 'parser/current'

module Tooling
  module Danger
    module DataDeletion
      MIGRATION_FILES_REGEX = %r{\A(?:ee/)?db/(?:(?:embedding|geo)/)?(?:post_)?migrate/.*\.rb\z}

      DATA_DELETION_LABEL = 'data-deletion'

      DELETION_METHODS = %w[
        drop_table
        truncate_tables
        remove_column
        remove_columns
        delete_all
        destroy_all
        drop_partitioned_table_for
        drop_nonpartitioned_archive_table
        drop_detached_partitions
      ].freeze

      DELETION_SQL = %w[
        DROP\s+TABLE
        DROP\s+COLUMN
        DELETE\s+FROM
        TRUNCATE
      ].freeze

      DELETION_MATCH =
        %r{\A\+(?!\s*\#).*?\b(?:#{DELETION_METHODS.join('|')}|#{DELETION_SQL.join('|')})\b}i

      HUNK_HEADER = /\A@@ -\d+(?:,\d+)? \+(?<new_start>\d+)(?:,\d+)? @@/

      DOCUMENTATION_LINK =
        'https://docs.gitlab.com/development/database_review/#preparation-when-adding-data-migrations'

      MISSING_LABEL_MESSAGE = <<~MSG.freeze
        ⚠️ **Data deletion detected in migration**

        The following migration(s) appear to delete data:

        %<migrations>s

        Please apply the ~"#{DATA_DELETION_LABEL}" label and update the merge request
        description with:

        1. How the data could be recovered in the event of an incident.
        2. The approximate number of records being affected.
        3. A description of the user experience impact.

        For more information, see the [database review documentation](#{DOCUMENTATION_LINK}).
      MSG

      def check_data_deletion_label
        return if helper.mr_labels.include?(DATA_DELETION_LABEL)

        deleting_migrations = migrations_with_data_deletion
        return if deleting_migrations.empty?

        fail format(MISSING_LABEL_MESSAGE, migrations: deleting_migrations.map { |m| "* `#{m}`" }.join("\n"))
      end

      private

      def migrations_with_data_deletion
        migration_files.select { |filename| flags_data_deletion?(filename) }
      end

      def migration_files
        helper.all_changed_files.grep(MIGRATION_FILES_REGEX)
      end

      # Anything outside `def down` is treated as forward-running, including
      # helpers called from `def up` and top-level execution.
      def flags_data_deletion?(filename)
        added_line_numbers = added_deletion_line_numbers(filename)
        return false if added_line_numbers.empty?

        down_ranges = down_method_ranges(filename)
        return false if down_ranges.nil?

        added_line_numbers.any? do |number|
          down_ranges.none? { |range| range.cover?(number) }
        end
      end

      # Reads new-file line numbers from hunk headers; content matching is
      # ambiguous when the same line appears more than once.
      def added_deletion_line_numbers(filename)
        patch = helper.git.diff_for_file(filename)&.patch
        return [] unless patch

        line_numbers = []
        current_line = nil

        patch.each_line do |raw|
          line = raw.chomp
          hunk_match = HUNK_HEADER.match(line)

          if hunk_match
            current_line = hunk_match[:new_start].to_i
          elsif current_line && !line.start_with?('+++', '---')
            case line[0]
            when '+'
              line_numbers << current_line if line.match?(DELETION_MATCH)
              current_line += 1
            when '-'
              # removed line; new-file numbering does not advance
            else
              current_line += 1
            end
          end
        end

        line_numbers
      end

      # Returns nil on parse failure (lenient fallback) and [] when there is
      # no `def down`.
      def down_method_ranges(filename)
        source = project_helper.file_lines(filename).join("\n")
        buffer = Parser::Source::Buffer.new('(source)', source: source)
        ast = Parser::CurrentRuby.new.parse(buffer)
        return unless ast

        visitor = DownMethodVisitor.new
        visitor.process(ast)
        visitor.method_ranges
      rescue Parser::SyntaxError
        nil
      end

      # AST Visitor that finds `def down` method ranges
      class DownMethodVisitor < Parser::AST::Processor
        attr_reader :method_ranges

        def initialize
          super
          @method_ranges = []
        end

        def on_def(node)
          if node.children.first == :down
            loc = node.location
            @method_ranges << (loc.line..loc.last_line)
          end

          super
        end
      end
    end
  end
end
