# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RescheduleBackfillImportedIssueSearchData, feature_category: :global_search do
  let!(:reschedule_migration) { described_class::MIGRATION }

  def create_batched_migration(max_value:)
    Gitlab::Database::BackgroundMigration::BatchedMigration
      .create!(
        max_value: max_value,
        batch_size: 200,
        sub_batch_size: 20,
        interval: 120,
        job_class_name: 'BackfillIssueSearchData',
        table_name: 'issues',
        column_name: 'id',
        gitlab_schema: 'glschema'
      )
  end

  shared_examples 'backfill rescheduler' do
    it 'schedules a new batched migration' do
      reversible_migration do |migration|
        migration.before -> {
          expect(reschedule_migration).not_to have_scheduled_batched_migration
        }
        migration.after -> {
          expect(reschedule_migration).to have_scheduled_batched_migration(
            table_name: :issues,
            column_name: :id,
            interval: described_class::DELAY_INTERVAL,
            batch_min_value: batch_min_value
          )
        }
      end
    end
  end

  context 'when BackfillIssueSearchData.max_value is nil' do
    let(:batch_min_value) { described_class::BATCH_MIN_VALUE }

    it_behaves_like 'backfill rescheduler'
  end

  context 'when BackfillIssueSearchData.max_value exists' do
    let(:batch_min_value) { described_class::BATCH_MIN_VALUE }

    before do
      create_batched_migration(max_value: 200)
    end

    it_behaves_like 'backfill rescheduler'
  end

  context 'when an issue is available' do
    let!(:namespaces_table) { table(:namespaces) }
    let!(:projects_table) { table(:projects) }

    let(:namespace) { namespaces_table.create!(name: 'gitlab-org', path: 'gitlab-org') }

    let(:project) do
      projects_table.create!(
        name: 'gitlab', path: 'gitlab-org/gitlab-ce', namespace_id: namespace.id, project_namespace_id: namespace.id
      )
    end

    let(:issue) do
      table(:issues).create!(
        project_id: project.id, namespace_id: project.project_namespace_id,
        title: 'test title', description: 'test description'
      )
    end

    before do
      create_batched_migration(max_value: max_value)
    end

    context 'when BackfillIssueSearchData.max_value = Issue.maximum(:id)' do
      let(:max_value) { issue.id }
      let(:batch_min_value) { max_value }

      it_behaves_like 'backfill rescheduler'
    end

    context 'when BackfillIssueSearchData.max_value > Issue.maximum(:id)' do
      let(:max_value) { issue.id + 1 }
      let(:batch_min_value) { issue.id }

      it_behaves_like 'backfill rescheduler'
    end

    context 'when BackfillIssueSearchData.max_value < Issue.maximum(:id)' do
      let(:max_value) { issue.id - 1 }
      let(:batch_min_value) { max_value }

      it_behaves_like 'backfill rescheduler'
    end
  end
end
