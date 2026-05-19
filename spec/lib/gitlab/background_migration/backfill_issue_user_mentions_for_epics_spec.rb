# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillIssueUserMentionsForEpics, feature_category: :portfolio_management do
  let(:epic_user_mentions) { table(:epic_user_mentions) }
  let(:epics) { table(:epics) }
  let(:issue_user_mentions) { table(:issue_user_mentions) }
  let(:issues) { table(:issues) }
  let(:namespaces) { table(:namespaces) }
  let(:notes) { table(:notes) }
  let(:organizations) { table(:organizations) }
  let(:users) { table(:users) }

  let!(:organization) { organizations.create!(id: 1, name: 'Default', path: 'default') }

  let(:user) do
    users.create!(
      email: 'test@example.com',
      username: 'testuser',
      name: 'Test User',
      projects_limit: 10,
      organization_id: 1
    )
  end

  let(:namespace) do
    namespaces.create!(name: 'test-group', path: 'test-group', type: 'Group', organization_id: 1)
  end

  # Work item type IDs are fixed now and only exist in memory. This one belongs to Epic.
  let(:work_item_type_id) { 8 }

  let(:issue) do
    issues.create!(
      title: 'Epic issue',
      namespace_id: namespace.id,
      work_item_type_id: work_item_type_id,
      lock_version: 0
    )
  end

  let(:epic) do
    epics.create!(
      title: 'Test epic',
      title_html: 'Test epic',
      group_id: namespace.id,
      author_id: user.id,
      issue_id: issue.id,
      iid: 1,
      lock_version: 0
    )
  end

  subject(:migration) do
    described_class.new(
      start_id: epic_user_mentions.minimum(:id),
      end_id: epic_user_mentions.maximum(:id),
      batch_table: :epic_user_mentions,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  describe '#perform' do
    context 'with a description mention' do
      before do
        epic_user_mentions.create!(
          epic_id: epic.id,
          group_id: namespace.id,
          mentioned_users_ids: [user.id],
          mentioned_projects_ids: nil,
          mentioned_groups_ids: [namespace.id]
        )
      end

      it 'backfills into issue_user_mentions' do
        expect { migration.perform }
          .to change { issue_user_mentions.where(issue_id: issue.id, note_id: nil).count }
          .from(0).to(1)
      end

      it 'copies the mention data correctly' do
        migration.perform

        mention = issue_user_mentions.find_by(issue_id: issue.id, note_id: nil)

        expect(mention.namespace_id).to eq(namespace.id)
        expect(mention.mentioned_users_ids).to eq([user.id])
        expect(mention.mentioned_groups_ids).to eq([namespace.id])
        expect(mention.mentioned_projects_ids).to be_nil
      end
    end

    context 'with a note mention' do
      let(:note) do
        notes.create!(
          note: 'Hello @testuser',
          noteable_type: 'Issue',
          noteable_id: issue.id,
          namespace_id: namespace.id
        )
      end

      before do
        epic_user_mentions.create!(
          epic_id: epic.id,
          group_id: namespace.id,
          note_id: note.id,
          mentioned_users_ids: [user.id],
          mentioned_projects_ids: nil,
          mentioned_groups_ids: nil
        )
      end

      it 'backfills into issue_user_mentions' do
        expect { migration.perform }
          .to change { issue_user_mentions.where(issue_id: issue.id).where.not(note_id: nil).count }
          .from(0).to(1)
      end

      it 'copies the mention data correctly' do
        migration.perform

        mention = issue_user_mentions.find_by(issue_id: issue.id, note_id: note.id)

        expect(mention.namespace_id).to eq(namespace.id)
        expect(mention.mentioned_users_ids).to eq([user.id])
        expect(mention.note_id).to eq(note.id)
      end
    end

    context 'with both description and note mentions' do
      let(:note) do
        notes.create!(
          note: 'Hello @testuser',
          noteable_type: 'Issue',
          noteable_id: issue.id,
          namespace_id: namespace.id
        )
      end

      before do
        epic_user_mentions.create!(
          epic_id: epic.id,
          group_id: namespace.id,
          mentioned_users_ids: [user.id],
          mentioned_projects_ids: nil,
          mentioned_groups_ids: nil
        )

        epic_user_mentions.create!(
          epic_id: epic.id,
          group_id: namespace.id,
          note_id: note.id,
          mentioned_users_ids: [user.id],
          mentioned_projects_ids: nil,
          mentioned_groups_ids: nil
        )
      end

      it 'backfills both mentions' do
        expect { migration.perform }
          .to change { issue_user_mentions.where(issue_id: issue.id).count }
          .from(0).to(2)
      end
    end

    context 'when issue_user_mention already has a record' do
      let(:other_user) do
        users.create!(
          email: 'other@example.com',
          username: 'otheruser',
          name: 'Other User',
          projects_limit: 10,
          organization_id: 1
        )
      end

      before do
        epic_user_mentions.create!(
          epic_id: epic.id,
          group_id: namespace.id,
          mentioned_users_ids: [user.id, other_user.id],
          mentioned_projects_ids: nil,
          mentioned_groups_ids: nil
        )

        # Preexisting record with stale data
        issue_user_mentions.create!(
          issue_id: issue.id,
          namespace_id: namespace.id,
          mentioned_users_ids: [user.id],
          mentioned_projects_ids: nil,
          mentioned_groups_ids: nil
        )
      end

      it 'upserts without creating duplicates' do
        expect { migration.perform }.not_to change { issue_user_mentions.where(issue_id: issue.id, note_id: nil).count }
      end

      it 'does not overwrite the existing record' do
        migration.perform

        mention = issue_user_mentions.find_by(issue_id: issue.id, note_id: nil)

        expect(mention.mentioned_users_ids).to eq([user.id])
      end
    end
  end
end
