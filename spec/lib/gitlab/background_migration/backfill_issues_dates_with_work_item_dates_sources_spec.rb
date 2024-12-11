# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillIssuesDatesWithWorkItemDatesSources,
  feature_category: :team_planning do
    let!(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }

    let!(:namespace) do
      table(:namespaces).create!(name: 'my test group1', path: 'my-test-group1', organization_id: organization.id)
    end

    let!(:author) { table(:users).create!(username: 'tester', projects_limit: 100) }
    let!(:epic_type_id) { table(:work_item_types).find_by(base_type: 7).id }

    let!(:issue_1) { work_items(iid: 1) }
    let!(:issue_2) { work_items(iid: 2) }
    let!(:unassociated_issue) { work_items(iid: 3) }

    let!(:date_source_1) do
      dates_source(
        work_item: issue_1,
        start_date: 1.day.ago,
        due_date: 1.day.from_now
      )
    end

    let!(:date_source_2) do
      dates_source(
        work_item: issue_2,
        start_date: 2.days.ago,
        due_date: 2.days.from_now
      )
    end

    subject(:migration) do
      described_class.new(
        start_id: WorkItems::DatesSource.minimum(:issue_id),
        end_id: WorkItems::DatesSource.maximum(:issue_id),
        batch_table: :work_item_dates_sources,
        batch_column: :issue_id,
        job_arguments: [nil],
        sub_batch_size: 2,
        pause_ms: 2,
        connection: ::ApplicationRecord.connection
      )
    end

    it 'backfills data correctly' do
      # Because we now also have a database trigger to ensure the work_item_dates_sources
      # dates are synced with work_items, we have to reload the objects in memory before we
      # can update them to ensure their start_date/due_date are nil
      issue_1.reload.update!(start_date: nil, due_date: nil)
      issue_2.reload.update!(start_date: nil, due_date: nil)

      expect { migration.perform }
        .to change { issue_1.reload.start_date }.from(nil).to(date_source_1.start_date)
        .and change { issue_1.reload.due_date }.from(nil).to(date_source_1.due_date)
        .and change { issue_2.reload.start_date }.from(nil).to(date_source_2.start_date)
        .and change { issue_2.reload.due_date }.from(nil).to(date_source_2.due_date)
        .and not_change { unassociated_issue.reload.start_date }
        .and not_change { unassociated_issue.reload.due_date }
    end

    private

    def work_items(iid:)
      table(:issues).create!(
        iid: iid,
        title: "Issue #{iid}",
        lock_version: 1,
        namespace_id: namespace.id,
        author_id: author.id,
        work_item_type_id: epic_type_id
      )
    end

    def dates_source(work_item:, start_date: nil, due_date: nil)
      table(:work_item_dates_sources).create!(
        issue_id: work_item.id,
        namespace_id: work_item.namespace_id,
        start_date: start_date,
        due_date: due_date
      )
    end
  end
