# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers -- Necessary for BBM setup
RSpec.describe Gitlab::BackgroundMigration::MigrateIssueTicketsIntoTicketType, feature_category: :service_desk do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:organization1) { organizations.create!(name: 'organization1', path: 'organization1') }
  let(:organization2) { organizations.create!(name: 'organization2', path: 'organization2') }
  let(:namespace) { namespaces.create!(name: 'namespace', path: 'namespace', organization_id: organization1.id) }
  let(:project) do
    table(:projects).create!(
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization1.id
    )
  end

  let(:bot_type) { 1 }
  let(:support_bot1) do
    table(:users).create!(
      user_type: bot_type,
      organization_id: organization1.id,
      projects_limit: 10,
      username: 'support-bot1',
      email: 'support1@gitlab.com'
    )
  end

  let(:support_bot2) do
    table(:users).create!(
      user_type: bot_type,
      organization_id: organization2.id,
      projects_limit: 10,
      username: 'support-bot2',
      email: 'support2@gitlab.com'
    )
  end

  let(:work_item_type_ids) do
    { issue: 1, incident: 2, test_case: 3, requirement: 4, task: 5, objective: 6, key_result: 7, epic: 8, ticket: 9 }
  end

  let(:issues_table) { table(:issues) }
  let!(:issue1) do
    issues_table.create!(
      project_id: project.id,
      namespace_id: namespace.id,
      work_item_type_id: work_item_type_ids[:issue]
    )
  end

  let!(:issue2) do
    issues_table.create!(
      project_id: project.id,
      namespace_id: namespace.id,
      work_item_type_id: work_item_type_ids[:issue]
    )
  end

  let!(:service_desk_issue1) do
    issues_table.create!(
      project_id: project.id,
      namespace_id: namespace.id,
      work_item_type_id: work_item_type_ids[:issue],
      author_id: support_bot1.id
    )
  end

  let!(:service_desk_issue2) do
    issues_table.create!(
      project_id: project.id,
      namespace_id: namespace.id,
      work_item_type_id: work_item_type_ids[:issue],
      author_id: support_bot1.id
    )
  end

  let!(:service_desk_issue3) do
    issues_table.create!(
      project_id: project.id,
      namespace_id: namespace.id,
      work_item_type_id: work_item_type_ids[:issue],
      author_id: support_bot2.id
    )
  end

  let!(:service_desk_issue4) do
    issues_table.create!(
      project_id: project.id,
      namespace_id: namespace.id,
      work_item_type_id: work_item_type_ids[:issue],
      author_id: support_bot2.id
    )
  end

  let!(:incident1) do
    issues_table.create!(
      project_id: project.id,
      namespace_id: namespace.id,
      work_item_type_id: work_item_type_ids[:incident]
    )
  end

  let!(:test_case1) do
    issues_table.create!(
      project_id: project.id,
      namespace_id: namespace.id,
      work_item_type_id: work_item_type_ids[:test_case]
    )
  end

  let!(:requirement1) do
    issues_table.create!(
      project_id: project.id,
      namespace_id: namespace.id,
      work_item_type_id: work_item_type_ids[:requirement]
    )
  end

  let!(:task1) do
    issues_table.create!(
      project_id: project.id,
      namespace_id: namespace.id,
      work_item_type_id: work_item_type_ids[:task]
    )
  end

  let!(:objective1) do
    issues_table.create!(
      project_id: project.id,
      namespace_id: namespace.id,
      work_item_type_id: work_item_type_ids[:objective]
    )
  end

  let!(:key_result1) do
    issues_table.create!(
      project_id: project.id,
      namespace_id: namespace.id,
      work_item_type_id: work_item_type_ids[:key_result]
    )
  end

  let!(:epic1) do
    issues_table.create!(
      project_id: project.id,
      namespace_id: namespace.id,
      work_item_type_id: work_item_type_ids[:epic]
    )
  end

  let!(:ticket1) do
    issues_table.create!(
      project_id: project.id,
      namespace_id: namespace.id,
      work_item_type_id: work_item_type_ids[:ticket]
    )
  end

  let(:start_id) { issues_table.minimum(:id) }
  let(:end_id) { issues_table.maximum(:id) }
  let(:service_desk_issues) { [service_desk_issue1, service_desk_issue2, service_desk_issue3, service_desk_issue4] }

  subject(:migration) do
    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :issues,
      batch_column: :id,
      sub_batch_size: 5,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  it 'changes work item type to ticket only on relevant issues' do
    expect do
      migration.perform
    end.to change { issue_type_unique_ids(service_desk_issues) }.from([work_item_type_ids[:issue]])
      .to([work_item_type_ids[:ticket]]).and(
        not_change { issue_type_unique_ids([issue1, issue2]) }.from([work_item_type_ids[:issue]])
      ).and(
        not_change { issue_type_unique_ids([incident1]) }.from([work_item_type_ids[:incident]])
      ).and(
        not_change { issue_type_unique_ids([test_case1]) }.from([work_item_type_ids[:test_case]])
      ).and(
        not_change { issue_type_unique_ids([requirement1]) }.from([work_item_type_ids[:requirement]])
      ).and(
        not_change { issue_type_unique_ids([task1]) }.from([work_item_type_ids[:task]])
      ).and(
        not_change { issue_type_unique_ids([objective1]) }.from([work_item_type_ids[:objective]])
      ).and(
        not_change { issue_type_unique_ids([key_result1]) }.from([work_item_type_ids[:key_result]])
      ).and(
        not_change { issue_type_unique_ids([epic1]) }.from([work_item_type_ids[:epic]])
      ).and(
        not_change { issue_type_unique_ids([ticket1]) }.from([work_item_type_ids[:ticket]])
      )
  end

  def issue_type_unique_ids(issues)
    issues.map { |i| i.reload.work_item_type_id }.uniq
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers
end
