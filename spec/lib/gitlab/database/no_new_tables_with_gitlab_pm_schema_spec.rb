# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'new tables with gitlab_pm schema', feature_category: :vulnerability_management do
  # During the decomposition of the gitlab_sec DB, we will be dropping the gitlab_pm schema
  # As part of this process, starting from milestone 17.3, it will be a mandatory requirement that
  # all newly created tables are associated gitlab_sec.
  # Any attempt to set the `gitlab_pm` schema for a new table will result in a failure of this spec.

  # Specific tables can be exempted from this requirement, and such tables must be added to the `exempted_tables` list.
  let!(:exempted_tables) do
    []
  end

  let!(:starting_from_milestone) { 17.3 }

  it 'only allows exempted tables to have `gitlab_pm` as its schema, after milestone 17.3', :aggregate_failures do
    tables_having_gitlab_pm_schema(starting_from_milestone: starting_from_milestone).each do |table_name|
      expect(exempted_tables).to include(table_name), error_message(table_name)
    end
  end

  private

  def error_message(table_name)
    <<~HEREDOC
      The table `#{table_name}` has been added with `gitlab_pm` schema.
      Starting from GitLab #{starting_from_milestone}, we expect new tables to use the `gitlab_sec` schema.

      Please see issue https://gitlab.com/gitlab-org/gitlab/-/issues/472608 to understand why this change is being enforced.
    HEREDOC
  end

  def tables_having_gitlab_pm_schema(starting_from_milestone:)
    gitlab_pm_schema_tables.filter_map do |entry|
      entry.table_name if entry.milestone_greater_than_or_equal_to?(starting_from_milestone)
    end
  end

  def gitlab_pm_schema_tables
    ::Gitlab::Database::Dictionary.entries.find_all_by_schema('gitlab_pm')
  end
end
