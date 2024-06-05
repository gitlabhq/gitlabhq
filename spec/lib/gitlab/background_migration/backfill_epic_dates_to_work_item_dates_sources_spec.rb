# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillEpicDatesToWorkItemDatesSources, feature_category: :team_planning do
  let!(:epic_type_id) { table(:work_item_types).find_by(base_type: 7).id }
  let!(:author) { table(:users).create!(username: 'tester', projects_limit: 100) }
  let!(:namespace) { table(:namespaces).create!(name: 'my test group1', path: 'my-test-group1') }

  let(:milestone) do
    table(:milestones).create!(
      title: 'Milestone',
      start_date: DateTime.parse('2024-01-01'),
      due_date: DateTime.parse('2024-01-31')
    )
  end

  let(:epics) { table(:epics) }
  let(:issues) { table(:issues) }
  let(:work_item_dates_sources) { table(:work_item_dates_sources) }
  let(:start_id) { epics.minimum(:id) }
  let(:end_id) { epics.maximum(:id) }

  let!(:fixed_epic_1) do
    create_epic_with_work_item(title: 'Epic 5', iid: 5, date_attrs: with_fixed_dates('2024-02-01', '2024-02-29'))
  end

  let!(:fixed_epic_2) do
    create_epic_with_work_item(title: 'Epic 6', iid: 6, date_attrs: with_fixed_dates('2024-03-01', '2024-03-31'))
  end

  let!(:fixed_epic_3) do
    create_epic_with_work_item(title: 'Epic 7', iid: 7, date_attrs: with_fixed_dates('2024-04-01', '2024-04-30'))
  end

  let!(:fixed_epic_4) do
    create_epic_with_work_item(title: 'Epic 8', iid: 8, date_attrs: with_fixed_dates('2024-05-01', '2024-05-31'))
  end

  let!(:fixed_epic_5) do
    create_epic_with_work_item(title: 'Epic 9', iid: 9, date_attrs: with_fixed_dates('2024-06-01', '2024-06-30'))
  end

  let!(:rolledup_epic_1) do
    create_epic_with_work_item(
      title: 'Epic 10',
      iid: 10,
      date_attrs: {
        start_date_is_fixed: false,
        due_date_is_fixed: false,
        start_date: fixed_epic_1.start_date,
        end_date: milestone.due_date,
        start_date_sourcing_milestone_id: nil,
        due_date_sourcing_milestone_id: milestone.id,
        start_date_sourcing_epic_id: fixed_epic_1.id,
        due_date_sourcing_epic_id: nil
      }
    )
  end

  let!(:rolledup_epic_2) do
    create_epic_with_work_item(
      title: 'Epic 11',
      iid: 11,
      date_attrs: {
        start_date_is_fixed: false,
        due_date_is_fixed: false,
        start_date: fixed_epic_2.start_date,
        end_date: fixed_epic_3.end_date,
        start_date_sourcing_milestone_id: nil,
        due_date_sourcing_milestone_id: nil,
        start_date_sourcing_epic_id: fixed_epic_2.id,
        due_date_sourcing_epic_id: fixed_epic_3.id
      }
    )
  end

  let!(:rolledup_epic_3) do
    create_epic_with_work_item(
      title: 'Epic 12',
      iid: 12,
      date_attrs: {
        start_date_is_fixed: false,
        due_date_is_fixed: nil,
        start_date_fixed: DateTime.parse('2024-07-01'),
        due_date_fixed: DateTime.parse('2024-07-31'),
        start_date: fixed_epic_4.start_date,
        end_date: fixed_epic_4.end_date,
        start_date_sourcing_milestone_id: nil,
        due_date_sourcing_milestone_id: nil,
        start_date_sourcing_epic_id: fixed_epic_4.id,
        due_date_sourcing_epic_id: fixed_epic_4.id
      }
    )
  end

  let!(:rolledup_epic_4) do
    create_epic_with_work_item(
      title: 'Epic 13',
      iid: 13,
      date_attrs: {
        start_date_is_fixed: false,
        due_date_is_fixed: false,
        start_date_fixed: DateTime.parse('2024-08-01'),
        due_date_fixed: DateTime.parse('2024-08-31'),
        start_date: fixed_epic_5.start_date,
        end_date: fixed_epic_5.end_date,
        start_date_sourcing_milestone_id: nil,
        due_date_sourcing_milestone_id: nil,
        start_date_sourcing_epic_id: fixed_epic_5.id,
        due_date_sourcing_epic_id: fixed_epic_5.id
      }
    )
  end

  let!(:rolledup_epic_5) do
    create_epic_with_work_item(
      title: 'Epic 14',
      iid: 14,
      date_attrs: {
        start_date_is_fixed: nil,
        due_date_is_fixed: true,
        start_date_fixed: DateTime.parse('2024-09-01'),
        due_date_fixed: DateTime.parse('2024-09-30'),
        start_date: fixed_epic_5.start_date,
        end_date: DateTime.parse('2024-09-30'),
        start_date_sourcing_milestone_id: nil,
        due_date_sourcing_milestone_id: nil,
        start_date_sourcing_epic_id: fixed_epic_5.id,
        due_date_sourcing_epic_id: nil
      }
    )
  end

  # Existing date_source for fixed_epic_1 that is not in sync
  let!(:not_synced_date_source) do
    work_item_dates_sources.create!(namespace_id: namespace.id, issue_id: fixed_epic_1.issue_id)
  end

  # Existing date_source for rolledup_epic_4 that is fully synced
  let!(:synced_date_source) do
    work_item_dates_sources.create!(
      namespace_id: namespace.id,
      issue_id: rolledup_epic_4.issue_id,
      start_date_is_fixed: rolledup_epic_4.start_date_is_fixed,
      due_date_is_fixed: rolledup_epic_4.due_date_is_fixed,
      start_date_fixed: rolledup_epic_4.start_date_fixed,
      due_date_fixed: rolledup_epic_4.due_date_fixed,
      start_date: rolledup_epic_4.start_date,
      due_date: rolledup_epic_4.end_date,
      start_date_sourcing_work_item_id: fixed_epic_5.issue_id,
      due_date_sourcing_work_item_id: fixed_epic_5.issue_id
    )
  end

  context 'when backfilling all epics', :aggregate_failures do
    subject(:migration) do
      described_class.new(
        start_id: start_id,
        end_id: end_id,
        batch_table: :epics,
        batch_column: :id,
        job_arguments: [nil],
        sub_batch_size: 2,
        pause_ms: 2,
        connection: ::ApplicationRecord.connection
      )
    end

    RSpec::Matchers.define :match_synced_work_item_dates do
      match do |epic|
        date_source = work_item_dates_sources.find_by_issue_id(epic.issue_id)

        expect(date_source.start_date).to eq epic.start_date
        expect(date_source.start_date_is_fixed).to eq epic.start_date_is_fixed.present?
        expect(date_source.due_date_is_fixed).to eq epic.due_date_is_fixed.present?
        expect(date_source.start_date_fixed).to eq epic.start_date_fixed
        expect(date_source.due_date_fixed).to eq epic.due_date_fixed
        expect(date_source.namespace_id).to eq(epic.group_id)
        expect(date_source.due_date).to eq(epic.end_date)
        expect(date_source.start_date_sourcing_milestone_id).to eq(epic.start_date_sourcing_milestone_id)
        expect(date_source.due_date_sourcing_milestone_id).to eq(epic.due_date_sourcing_milestone_id)
        expect(date_source.start_date_sourcing_work_item_id)
          .to eq(epics.find_by_id(epic.start_date_sourcing_epic_id)&.issue_id)
        expect(date_source.due_date_sourcing_work_item_id)
          .to eq(epics.find_by_id(epic.due_date_sourcing_epic_id)&.issue_id)
      end
    end

    it 'backfills data correctly' do
      expect do
        migration.perform
      end.to change { work_item_dates_sources.count }.from(2).to(10).and not_change { synced_date_source }

      expect(epics.all).to all(match_synced_work_item_dates)
    end
  end

  def create_epic_with_work_item(iid:, title:, date_attrs: {})
    wi = issues.create!(
      iid: iid,
      author_id: author.id,
      work_item_type_id: epic_type_id,
      namespace_id: namespace.id,
      lock_version: 1,
      title: title
    )

    epic_attributes = {
      iid: iid,
      title: title,
      title_html: title,
      group_id: namespace.id,
      author_id: author.id,
      issue_id: wi.id
    }

    epics.create!(epic_attributes.merge!(date_attrs))
  end

  def with_fixed_dates(start_date, due_date)
    {
      start_date: DateTime.parse(start_date),
      end_date: DateTime.parse(due_date),
      start_date_fixed: DateTime.parse(start_date),
      due_date_fixed: DateTime.parse(due_date),
      start_date_is_fixed: true,
      due_date_is_fixed: true
    }
  end
end
