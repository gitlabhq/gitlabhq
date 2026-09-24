# frozen_string_literal: true

module Tooling
  module Danger
    module RetentionPolicyAllowlist
      ALLOWLIST_PATH = 'spec/support/database/retention-policy-missing-allowlist.yml'

      # Matches an added YAML list entry like `+- some_table_name`.
      # Tolerates optional single/double quotes around the value and a
      # trailing YAML comment so hand-edited additions can't slip past the guard.
      ADDED_ENTRY_REGEX = /\A\+-\s+(?<quote>['"]?)(?<table>[^'"\s#]+)\k<quote>\s*(?:#.*)?\z/

      DOC_URL = 'https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/data_retention_policy_framework/'

      FAILURE_MESSAGE = <<~MSG.freeze
        ⛔ **New tables must not be added to `#{ALLOWLIST_PATH}`**

        The following tables were added to the retention policy allowlist:

        %<tables>s

        This allowlist only exists to grandfather in existing tables that predate the
        [Data Retention Policy Framework](#{DOC_URL}).
        New tables must declare a retention policy in `db/docs/data_retention/<table_name>.yml`
        instead of being skipped here.
      MSG

      def check_retention_policy_allowlist_additions
        return unless helper.all_changed_files.include?(ALLOWLIST_PATH)

        added_tables = added_allowlist_entries
        return if added_tables.empty?

        fail format(FAILURE_MESSAGE, tables: added_tables.map { |t| "  - `#{t}`" }.join("\n"))
      end

      private

      def added_allowlist_entries
        helper.changed_lines(ALLOWLIST_PATH).filter_map do |line|
          ADDED_ENTRY_REGEX.match(line)&.[](:table)
        end
      end
    end
  end
end
