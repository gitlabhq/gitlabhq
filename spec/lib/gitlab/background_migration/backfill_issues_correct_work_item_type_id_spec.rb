# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillIssuesCorrectWorkItemTypeId,
  feature_category: :team_planning,
  schema: 20241030165330 do
  around do |example|
    columns = missing_bigint_columns
    add_missing_columns(columns)
    example.run
    drop_missing_columns(columns)
  end

  let(:batch_column) { 'id' }
  let(:sub_batch_size) { 2 }
  let(:pause_ms) { 0 }

  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:namespace) { table(:namespaces).create!(name: 'namespace', path: 'namespace', organization_id: organization.id) }
  let(:project) do
    table(:projects).create!(
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id
    )
  end

  let(:issue_type_enum) { { issue: 0, incident: 1, test_case: 2, requirement: 3, task: 4 } }
  let(:issues_table) { table(:issues) }
  let(:issue_type) { table(:work_item_types).find_by!(base_type: issue_type_enum[:issue]) }
  let(:task_type) { table(:work_item_types).find_by!(base_type: issue_type_enum[:task]) }
  let(:incident_type) { table(:work_item_types).find_by!(base_type: issue_type_enum[:incident]) }
  let(:test_case_type) { table(:work_item_types).find_by!(base_type: issue_type_enum[:test_case]) }
  let(:requirement_type) { table(:work_item_types).find_by!(base_type: issue_type_enum[:requirement]) }

  let(:issue1) do
    issues_table.create!(project_id: project.id, namespace_id: namespace.id, work_item_type_id: issue_type.id)
  end

  let(:issue2) do
    issues_table.create!(project_id: project.id, namespace_id: namespace.id, work_item_type_id: issue_type.id)
  end

  let(:issue3) do
    issues_table.create!(project_id: project.id, namespace_id: namespace.id, work_item_type_id: issue_type.id)
  end

  let(:incident1) do
    issues_table.create!(project_id: project.id, namespace_id: namespace.id, work_item_type_id: incident_type.id)
  end

  # test_case and requirement are EE only, but enum values exist on the FOSS model
  let(:test_case1) do
    issues_table.create!(project_id: project.id, namespace_id: namespace.id, work_item_type_id: test_case_type.id)
  end

  let(:requirement1) do
    issues_table.create!(project_id: project.id, namespace_id: namespace.id, work_item_type_id: requirement_type.id)
  end

  let(:start_id) { issue1.id }
  let(:end_id) { requirement1.id }

  let!(:all_issues) { [issue1, issue2, issue3, incident1, test_case1, requirement1] }

  let(:migration) do
    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :issues,
      batch_column: :id,
      sub_batch_size: sub_batch_size,
      pause_ms: pause_ms,
      job_arguments: [issue_type.id, issue_type.correct_id],
      connection: base_connection
    )
  end

  subject(:migrate) { migration.perform }

  it 'sets correct_work_item_type_id for all records in batches' do
    expect(all_issues).to all(have_attributes(correct_work_item_type_id: 0))

    expect { migrate }.to make_queries_matching(
      /"correct_work_item_type_id" = "work_item_types"."correct_id"/,
      3
    )
    all_issues.each(&:reload)

    expect([issue1, issue2, issue3]).to all(have_attributes(correct_work_item_type_id: issue_type.correct_id))
    expect(incident1).to have_attributes(correct_work_item_type_id: incident_type.correct_id)
    expect(test_case1).to have_attributes(correct_work_item_type_id: test_case_type.correct_id)
    expect(requirement1).to have_attributes(correct_work_item_type_id: requirement_type.correct_id)
  end

  it 'tracks timings of queries' do
    expect(migration.batch_metrics.timings).to be_empty

    expect { migrate }.to change { migration.batch_metrics.timings }
  end

  private

  def missing_bigint_columns
    column_names = base_connection.columns(:issues).map(&:name)
    expected_columns = %w[
      author_id_convert_to_bigint
      closed_by_id_convert_to_bigint
      duplicated_to_id_convert_to_bigint
      id_convert_to_bigint
      last_edited_by_id_convert_to_bigint
      milestone_id_convert_to_bigint
      moved_to_id_convert_to_bigint
      project_id_convert_to_bigint
      promoted_to_epic_id_convert_to_bigint
      updated_by_id_convert_to_bigint
    ]
    expected_columns - column_names
  end

  def add_missing_columns(columns)
    return if columns.blank?

    add_columns_expression = columns.map { |c| "ADD COLUMN IF NOT EXISTS #{c} bigint" }.join(',')
    base_connection.execute <<~SQL
      ALTER TABLE issues #{add_columns_expression};
    SQL
  end

  def drop_missing_columns(columns)
    return if columns.blank?

    drop_columns_expression = columns.map { |c| "DROP COLUMN IF EXISTS #{c}" }.join(',')
    base_connection.execute <<~SQL
      ALTER TABLE issues #{drop_columns_expression};
    SQL
  end

  def base_connection
    ::ApplicationRecord.connection
  end
end
