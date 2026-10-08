# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDriftedWorkItemTransitions,
  feature_category: :team_planning do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:issues) { table(:issues) }
  let(:epics) { table(:epics) }
  let(:users) { table(:users) }
  let(:transitions) { table(:work_item_transitions) }

  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }

  let(:group) do
    namespaces.create!(name: 'group', path: 'group', type: 'Group', organization_id: organization.id)
  end

  let(:user) do
    users.create!(
      username: 'author', email: 'author@example.com', projects_limit: 10, organization_id: organization.id
    )
  end

  let(:issue_work_item_type_id) { 1 }

  # Target of a move/duplicate/promote, so the columns hold a plausible value.
  let!(:other_issue) { create_issue(iid: 99) }

  let!(:drifted) { create_issue(iid: 1, moved_to_id: other_issue.id) }
  let!(:in_sync) { create_issue(iid: 2, duplicated_to_id: other_issue.id) }
  let!(:stale_value) { create_issue(iid: 3) }

  # promoted_to_epic_id references epics, not issues.
  let!(:epic) do
    epics.create!(
      group_id: group.id, author_id: user.id, iid: 1,
      title: 'epic', title_html: 'epic', issue_id: create_issue(iid: 98).id
    )
  end

  # `trigger_sync_work_item_transitions_from_issues` fires on insert, so creating an issue also
  # creates its transitions row. Drift is reproduced the way it happened in production: by leaving
  # the transitions row holding a value the issue no longer has.
  def create_issue(iid:, **attrs)
    issues.create!(
      title: "issue #{iid}",
      iid: iid,
      namespace_id: group.id,
      work_item_type_id: issue_work_item_type_id,
      **attrs
    )
  end

  def drift(issue, **attrs)
    transitions.where(work_item_id: issue.id).update_all(**attrs)
  end

  def transition_for(issue)
    transitions.find_by(work_item_id: issue.id)
  end

  # Unchanged xmin means the UPDATE never touched the row, so the IS DISTINCT FROM
  # guard kept it out of the write set.
  def row_version(issue)
    transitions.connection.select_value(
      "SELECT xmin FROM work_item_transitions WHERE work_item_id = #{issue.id}"
    )
  end

  def perform_migration(end_id: transitions.maximum(:work_item_id))
    described_class.new(
      start_cursor: [transitions.minimum(:work_item_id)],
      end_cursor: [end_id],
      batch_table: :work_item_transitions,
      batch_column: :work_item_id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    ).perform
  end

  describe '#perform' do
    before do
      # The update that set moved_to_id never reached the transitions row.
      drift(drifted, moved_to_id: nil)
      # The issue has no promotion, but the transitions row still claims one.
      drift(stale_value, promoted_to_epic_id: epic.id)
    end

    it 'copies the current issue value onto the drifted row' do
      perform_migration

      expect(transition_for(drifted).moved_to_id).to eq(other_issue.id)
    end

    it 'clears a value that no longer exists on the issue' do
      perform_migration

      expect(transition_for(stale_value).promoted_to_epic_id).to be_nil
    end

    it 'leaves rows that already match untouched', :aggregate_failures do
      version = row_version(in_sync)

      perform_migration

      expect(transition_for(in_sync).duplicated_to_id).to eq(other_issue.id)
      expect(row_version(in_sync)).to eq(version)
    end

    it 'stops at the end cursor' do
      later = create_issue(iid: 4, moved_to_id: other_issue.id)
      drift(later, moved_to_id: nil)

      perform_migration(end_id: drifted.id)

      expect(transition_for(later).moved_to_id).to be_nil
    end

    it 'is idempotent' do
      perform_migration

      expect { perform_migration }
        .not_to change { transitions.order(:work_item_id).pluck(:moved_to_id, :duplicated_to_id, :promoted_to_epic_id) }
    end
  end
end
