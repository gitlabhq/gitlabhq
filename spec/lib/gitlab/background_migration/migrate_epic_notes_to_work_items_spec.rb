# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MigrateEpicNotesToWorkItems, feature_category: :portfolio_management do
  let(:notes) { table(:notes) }
  let(:epics) { table(:epics) }
  let(:issues) { table(:issues) }
  let(:namespaces) { table(:namespaces) }
  let(:users) { table(:users) }
  let(:organizations) { table(:organizations) }

  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let(:group) { namespaces.create!(name: 'group', path: 'group', type: 'Group', organization_id: organization.id) }

  let(:user) do
    users.create!(
      username: 'test_user',
      email: 'test@example.com',
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let(:epic_work_item_type_id) { 8 }
  let!(:work_item1) do
    issues.create!(
      title: 'Issue 1',
      id: 1,
      iid: 1,
      namespace_id: group.id,
      work_item_type_id: epic_work_item_type_id
    )
  end

  let!(:work_item2) do
    issues.create!(
      title: 'Issue 2',
      id: 2,
      iid: 2,
      namespace_id: group.id,
      work_item_type_id: epic_work_item_type_id
    )
  end

  let!(:epic1) do
    epics.create!(
      id: 3,
      iid: 3,
      group_id: group.id,
      author_id: user.id,
      title: 'Epic 1',
      title_html: 'Epic 1',
      issue_id: work_item1.id
    )
  end

  let!(:epic2) do
    epics.create!(
      id: 4,
      iid: 4,
      group_id: group.id,
      author_id: user.id,
      title: 'Epic 2',
      title_html: 'Epic 2',
      issue_id: work_item2.id
    )
  end

  let!(:epic1_note) do
    notes.create!(
      noteable_type: 'Epic',
      noteable_id: epic1.id,
      note: 'epic1 unique note',
      author_id: user.id,
      namespace_id: group.id
    )
  end

  let!(:epic2_note) do
    notes.create!(
      noteable_type: 'Epic',
      noteable_id: epic2.id,
      note: 'epic2 note',
      author_id: user.id,
      namespace_id: group.id
    )
  end

  let!(:other_issue_note) do
    notes.create!(
      noteable_type: 'Issue',
      noteable_id: work_item1.id,
      note: 'other issue note',
      author_id: user.id,
      namespace_id: group.id
    )
  end

  let(:migration) do
    described_class.new(
      batch_table: :epics,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  describe '#perform' do
    subject(:perform_migration) { migration.perform }

    it 'migrates epic notes to issue notes' do
      expect { perform_migration }.to change {
        notes.where(noteable_type: 'Epic').count
      }.from(2).to(0)
      .and change {
        notes.where(noteable_type: 'Issue').count
      }.from(1).to(3)

      expect(notes.find(epic1_note.id)).to have_attributes(
        noteable_type: 'Issue',
        noteable_id: work_item1.id,
        note: 'epic1 unique note'
      )

      expect(notes.find(epic2_note.id)).to have_attributes(
        noteable_type: 'Issue',
        noteable_id: work_item2.id,
        note: 'epic2 note'
      )

      expect(notes.find(other_issue_note.id)).to have_attributes(
        noteable_type: 'Issue',
        noteable_id: work_item1.id,
        note: 'other issue note'
      )
    end
  end
end
