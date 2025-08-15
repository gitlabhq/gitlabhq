# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'no new tables using gitlab_main_cell schema', feature_category: :cell do
  # Starting from milestone 18.4, it is not allowed for any tables to use gitlab_main_cell.
  # Any attempt to set the `gitlab_main_cell` schema for a new table will result in a failure of this spec.

  # Specific tables can be temporarily exempted from this requirement,
  # and such tables must be added to the `exempted_tables` list with an issue link as as comment.
  let(:exempted_tables) { [] }

  let(:milestone_cutoff) { 18.4 }

  it 'only allows exempted tables to have `gitlab_main_cell` as its schema', :aggregate_failures do
    new_gitlab_main_cell_schema_tables(milestone_cutoff: milestone_cutoff).each do |table_name|
      expect(exempted_tables).to include(table_name), error_message(table_name)
    end
  end

  it 'only allows tables having `gitlab_main_cell` as its schema in `exempted_tables`', :aggregate_failures do
    tables_having_gitlab_main_cell_schema = gitlab_main_cell_schema_tables.map(&:table_name)

    exempted_tables.each do |exempted_table|
      expect(tables_having_gitlab_main_cell_schema).to include(exempted_table),
        "`#{exempted_table}` does not have `gitlab_main_cell` as its schema.
        Please remove this table from the `exempted_tables` list."
    end
  end

  private

  def error_message(table_name)
    <<~MSG
      The table `#{table_name}` is using the `gitlab_main_cell` schema,
      which is no longer allowed starting from GitLab #{milestone_cutoff}.

      Please use one of the following schemas instead:
        - `gitlab_main_org`
        - `gitlab_main_cell_local`
        - `gitlab_main_user`

      See: https://docs.gitlab.com/ee/development/cells/#available-cells--organization-schemas
      or consult the Tenant Scale group for guidance.
    MSG
  end

  def new_gitlab_main_cell_schema_tables(milestone_cutoff:)
    gitlab_main_cell_schema_tables.filter_map do |entry|
      entry.table_name if entry.milestone_greater_than_or_equal_to?(milestone_cutoff)
    end
  end

  def gitlab_main_cell_schema_tables
    ::Gitlab::Database::Dictionary.entries.find_all_by_schema('gitlab_main_cell')
  end
end
