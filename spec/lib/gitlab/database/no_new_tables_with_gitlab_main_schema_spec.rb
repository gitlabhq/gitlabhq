# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'new tables with gitlab_main schema', feature_category: :cell do
  # During the development of Cells, we will be moving tables from the `gitlab_main` schema
  # to either the `gitlab_main_clusterwide` or `gitlab_main_cell` schema.
  # As part of this process, starting from milestone 16.7, it will be a mandatory requirement that
  # all newly created tables are associated with one of these two schemas.
  # Any attempt to set the `gitlab_main` schema for a new table will result in a failure of this spec.

  # Specific tables can be exempted from this requirement, and such tables must be added to the `exempted_tables` list.
  let!(:exempted_tables) do
    []
  end

  let!(:starting_from_milestone) { 16.7 }

  it 'only allows exempted tables to have `gitlab_main` as its schema, after milestone 16.7', :aggregate_failures do
    tables_having_gitlab_main_schema(starting_from_milestone: starting_from_milestone).each do |table_name|
      expect(exempted_tables).to include(table_name), error_message(table_name)
    end
  end

  it 'only allows tables having `gitlab_main` as its schema in `exempted_tables`', :aggregate_failures do
    tables_having_gitlab_main_schema = gitlab_main_schema_tables.map(&:table_name)

    exempted_tables.each do |exempted_table|
      expect(tables_having_gitlab_main_schema).to include(exempted_table),
        "`#{exempted_table}` does not have `gitlab_main` as its schema.
        Please remove this table from the `exempted_tables` list."
    end
  end

  private

  def error_message(table_name)
    <<~HEREDOC
      The table `#{table_name}` has been added with `gitlab_main` schema.
      Starting from GitLab #{starting_from_milestone}, we expect new tables to use either the `gitlab_main_cell` or the
      `gitlab_main_clusterwide` schema.

      To choose an appropriate schema for this table from among `gitlab_main_cell` and `gitlab_main_clusterwide`, please refer
      to our guidelines at https://docs.gitlab.com/ee/development/cells/#choose-either-the-gitlab_main_cell-or-gitlab_main_clusterwide-schema, or consult with the Tenant Scale group.

      Please see issue https://gitlab.com/gitlab-org/gitlab/-/issues/424990 to understand why this change is being enforced.
    HEREDOC
  end

  def tables_having_gitlab_main_schema(starting_from_milestone:)
    gitlab_main_schema_tables.filter_map do |entry|
      entry.table_name if entry.milestone_greater_than_or_equal_to?(starting_from_milestone)
    end
  end

  def gitlab_main_schema_tables
    ::Gitlab::Database::Dictionary.entries.find_all_by_schema('gitlab_main')
  end
end
