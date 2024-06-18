# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::ResyncBasicEpicFieldsToWorkItem, feature_category: :team_planning do
  let!(:author) { table(:users).create!(username: 'tester', projects_limit: 100) }
  let!(:namespace1) { table(:namespaces).create!(name: 'my test group1', path: 'my-test-group1') }
  let!(:namespace2) { table(:namespaces).create!(name: 'my test group2', path: 'my-test-group2') }
  let!(:epics) { table(:epics) }
  let!(:issues) { table(:issues) }
  let!(:wi_colors) { table(:work_item_colors) }
  let!(:start_id) { epics.minimum(:id) }
  let!(:end_id) { epics.maximum(:id) }
  let!(:epic_work_item_type_id) { table(:work_item_types).where(base_type: 7).first.id }

  before do
    (1..5).each do |idx|
      epic_data = epic_data(idx, namespace1)
      issue_id = issues.create!(
        title: "out of sync #{idx}", iid: idx, namespace_id: namespace1.id, work_item_type_id: epic_work_item_type_id
      ).id

      table(:epics).create!(**epic_data, issue_id: issue_id)
      # synced work items have the same color as the epic
      color_data = { issue_id: issue_id, namespace_id: namespace1.id, color: epic_data[:color] }
      table(:work_item_colors).create!(color_data) if idx % 3 == 0
    end

    (6..10).each do |idx|
      issue_id = issues.create!(
        title: "epic #{idx}", iid: idx, namespace_id: namespace2.id, work_item_type_id: epic_work_item_type_id
      ).id

      table(:epics).create!(**epic_data(idx, namespace2), issue_id: issue_id)
      # synced work items have a different color from epics
      color_data = { issue_id: issue_id, namespace_id: namespace2.id, color: color((idx * 1000) + 1) }
      table(:work_item_colors).create!(color_data) if idx % 3 == 0
    end
  end

  context 'when backfilling all epics', :aggregate_failures do
    let!(:migration) do
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

    it 'backfills the work items for specific group only' do
      migration.perform

      backfilled_epics = epics.where.not(issue_id: nil)
      expect(backfilled_epics.count).to eq(10)
      expect(backfilled_epics.map(&:group_id).uniq).to match_array([namespace1.id, namespace2.id])

      epic_wis = table(:issues).where(work_item_type_id: epic_work_item_type_id)
      epic_wi_colors = wi_colors.where(issue_id: backfilled_epics.pluck(:issue_id))

      expect(epic_wis.map(&:namespace_id).uniq).to match_array([namespace1.id, namespace2.id])
      expect(epic_wis.map(&:iid).uniq).to match_array(backfilled_epics.map(&:iid).uniq)
      expect(epic_wis.map(&:title).uniq).to match_array(backfilled_epics.map(&:title).uniq)

      # all colors on the work items with a color should be the same as the epic colors
      expect(epic_wi_colors.map { |wi_color| [wi_color.issue_id, wi_color.color] }).to match_array(
        backfilled_epics.where(issue_id: epic_wi_colors.pluck(:issue_id)).map { |epic| [epic.issue_id, epic.color] }
      )

      # for colors not linked to an epic work item we should have epics on default color
      default_color_epics = backfilled_epics.where.not(issue_id: epic_wi_colors.pluck(:issue_id)).pluck(:color).uniq
      expect(default_color_epics).to eq(['#1068bf'])
    end
  end

  def epic_data(idx, namespace)
    {
      title: "epic #{idx}",
      title_html: "epic #{idx}",
      iid: idx,
      author_id: author.id,
      # this is to reproduce the PG::ForeignKeyViolation handled in
      # BackfillEpicBasicFieldsToWorkItemRecord#build_work_items by fetching the updated_by_user_ids data
      updated_by_id: idx.even? ? author.id : rand(10_000),
      group_id: namespace.id,
      # set every other epic color to default one
      color: idx.even? ? color(idx * 1000) : '#1068bf'
    }
  end

  def color(idx)
    "##{idx.to_s(16).rjust(6, '0')}"
  end
end
