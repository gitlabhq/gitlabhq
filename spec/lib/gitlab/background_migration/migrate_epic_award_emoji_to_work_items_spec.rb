# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MigrateEpicAwardEmojiToWorkItems, feature_category: :portfolio_management do
  let(:award_emoji) { table(:award_emoji) }
  let(:epics) { table(:epics) }
  let(:issues) { table(:issues) }
  let(:namespaces) { table(:namespaces) }
  let(:users) { table(:users) }
  let(:organizations) { table(:organizations) }

  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let(:group) { namespaces.create!(name: 'group', path: 'group', type: 'Group', organization_id: organization.id) }

  let(:user1) do
    users.create!(
      username: 'test_user_1',
      email: 'test1@example.com',
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let(:user2) do
    users.create!(
      username: 'test_user_2',
      email: 'test2@example.com',
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let(:epic_work_item_type_id) { 8 }
  let(:work_item1) do
    issues.create!(
      title: 'Issue 1',
      id: 1,
      iid: 1,
      namespace_id: group.id,
      work_item_type_id: epic_work_item_type_id
    )
  end

  let(:work_item2) do
    issues.create!(
      title: 'Issue 2',
      id: 2,
      iid: 2,
      namespace_id: group.id,
      work_item_type_id: epic_work_item_type_id
    )
  end

  let(:epic1) do
    epics.create!(
      id: 4,
      iid: 4,
      group_id: group.id,
      author_id: user1.id,
      title: 'Epic 1',
      title_html: 'Epic 1',
      issue_id: work_item1.id
    )
  end

  let(:epic2) do
    epics.create!(
      id: 5,
      iid: 5,
      group_id: group.id,
      author_id: user1.id,
      title: 'Epic 2',
      title_html: 'Epic 2',
      issue_id: work_item2.id
    )
  end

  let!(:epic1_award_emoji) do
    award_emoji.create!(
      awardable_type: 'Epic',
      awardable_id: epic1.id,
      user_id: user2.id,
      name: 'rocket',
      namespace_id: group.id
    )
  end

  let!(:epic2_award_emoji) do
    award_emoji.create!(
      awardable_type: 'Epic',
      awardable_id: epic2.id,
      user_id: user1.id,
      name: 'tada',
      namespace_id: group.id
    )
  end

  let!(:epic1_work_item_award_emoji) do
    award_emoji.create!(
      awardable_type: 'Issue',
      awardable_id: work_item1.id,
      user_id: user2.id,
      name: 'clapper',
      namespace_id: group.id
    )
  end

  let!(:epic2_work_item_award_emoji) do
    award_emoji.create!(
      awardable_type: 'Issue',
      awardable_id: work_item2.id,
      user_id: user2.id,
      name: 'thumbsup',
      namespace_id: group.id
    )
  end

  let(:migration) do
    start_id, end_id = epics.pick('MIN(id), MAX(id)')

    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :epics,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      job_arguments: [],
      connection: ApplicationRecord.connection
    )
  end

  describe '#perform' do
    subject(:perform_migration) { migration.perform }

    it 'migrates epic award emoji to issue award emoji' do
      expect { perform_migration }.to change {
        award_emoji.where(awardable_type: 'Epic').count
      }.from(2).to(0)
      .and change {
        award_emoji.where(awardable_type: 'Issue').count
      }.from(2).to(4)

      expect(award_emoji.find(epic1_award_emoji.id)).to have_attributes(
        awardable_type: 'Issue',
        awardable_id: work_item1.id,
        user_id: user2.id,
        name: 'rocket'
      )

      expect(award_emoji.find(epic2_award_emoji.id)).to have_attributes(
        awardable_type: 'Issue',
        awardable_id: work_item2.id,
        user_id: user1.id,
        name: 'tada'
      )

      expect(award_emoji.find(epic1_work_item_award_emoji.id)).to have_attributes(
        awardable_type: 'Issue',
        awardable_id: work_item1.id,
        user_id: user2.id,
        name: 'clapper'
      )

      expect(award_emoji.find(epic2_work_item_award_emoji.id)).to have_attributes(
        awardable_type: 'Issue',
        awardable_id: work_item2.id,
        user_id: user2.id,
        name: 'thumbsup'
      )
    end

    context 'when duplicate issue award exists' do
      let!(:duplicate_epic_award_emoji) do
        award_emoji.create!(
          awardable_type: 'Epic',
          awardable_id: epic1.id,
          user_id: epic1_work_item_award_emoji.user_id,
          name: epic1_work_item_award_emoji.name,
          namespace_id: group.id
        )
      end

      it 'removes duplicate epic award emoji before migration' do
        expect { perform_migration }.to change {
          award_emoji.where(awardable_type: 'Epic').count
        }.from(3).to(0)
        .and change {
          award_emoji.where(awardable_type: 'Issue').count
        }.from(2).to(4)

        expect { award_emoji.find(duplicate_epic_award_emoji.id) }
          .to raise_error(ActiveRecord::RecordNotFound)

        expect(award_emoji.find(epic1_award_emoji.id)).to have_attributes(
          awardable_type: 'Issue',
          awardable_id: work_item1.id,
          user_id: user2.id,
          name: 'rocket'
        )

        expect(award_emoji.find(epic2_award_emoji.id)).to have_attributes(
          awardable_type: 'Issue',
          awardable_id: work_item2.id,
          user_id: user1.id,
          name: 'tada'
        )

        expect(award_emoji.find(epic1_work_item_award_emoji.id)).to have_attributes(
          awardable_type: 'Issue',
          awardable_id: work_item1.id,
          user_id: user2.id,
          name: 'clapper'
        )

        expect(award_emoji.find(epic2_work_item_award_emoji.id)).to have_attributes(
          awardable_type: 'Issue',
          awardable_id: work_item2.id,
          user_id: user2.id,
          name: 'thumbsup'
        )
      end
    end

    context 'when one epic has multiple award emoji duplicates' do
      let!(:epic1_award_emoji_additional1) do
        award_emoji.create!(
          awardable_type: 'Epic',
          awardable_id: epic1.id,
          user_id: user2.id,
          name: 'cat',
          namespace_id: group.id
        )
      end

      let!(:epic1_award_emoji_additional2) do
        award_emoji.create!(
          awardable_type: 'Epic',
          awardable_id: epic1.id,
          user_id: user2.id,
          name: 'dog',
          namespace_id: group.id
        )
      end

      let!(:epic1_work_item_award_emoji_additional1) do
        award_emoji.create!(
          awardable_type: 'Issue',
          awardable_id: work_item1.id,
          user_id: user2.id,
          name: 'cat',
          namespace_id: group.id
        )
      end

      let!(:epic1_work_item_award_emoji_additional2) do
        award_emoji.create!(
          awardable_type: 'Issue',
          awardable_id: work_item1.id,
          user_id: user2.id,
          name: 'dog',
          namespace_id: group.id
        )
      end

      it 'migrates epic award emoji to issue award emoji' do
        expect { perform_migration }.to change {
          award_emoji.where(awardable_type: 'Epic').count
        }.from(4).to(0)
         .and change {
           award_emoji.where(awardable_type: 'Issue').count
         }.from(4).to(6)

        expect(award_emoji.find(epic1_work_item_award_emoji_additional1.id)).to have_attributes(
          awardable_type: 'Issue',
          awardable_id: work_item1.id,
          user_id: user2.id,
          name: 'cat'
        )

        expect(award_emoji.find(epic1_work_item_award_emoji_additional2.id)).to have_attributes(
          awardable_type: 'Issue',
          awardable_id: work_item1.id,
          user_id: user2.id,
          name: 'dog'
        )
        expect { award_emoji.find(epic1_award_emoji_additional1.id) }
          .to raise_error(ActiveRecord::RecordNotFound)
        expect { award_emoji.find(epic1_award_emoji_additional2.id) }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'for emoji award for non-epic' do
      let(:work_item3) do
        issues.create!(
          title: 'Issue 3',
          id: 3,
          iid: 3,
          namespace_id: group.id,
          work_item_type_id: 1
        )
      end

      let!(:issue_work_item_award_emoji) do
        award_emoji.create!(
          awardable_type: 'Issue',
          awardable_id: work_item3.id,
          user_id: user2.id,
          name: 'thumbsup',
          namespace_id: group.id
        )
      end

      it 'does not change non-epic award emoji' do
        expect { perform_migration }.not_to change { issue_work_item_award_emoji.awardable_id }
      end
    end

    context 'when migration runs twice (idempotency)' do
      it 'is idempotent and does not cause errors on second run' do
        perform_migration

        epic_count_after_first = award_emoji.where(awardable_type: 'Epic').count
        issue_count_after_first = award_emoji.where(awardable_type: 'Issue').count

        expect(epic_count_after_first).to eq(0)
        expect(issue_count_after_first).to eq(4)

        expect { migration.perform }.not_to raise_error

        expect(award_emoji.where(awardable_type: 'Epic').count).to eq(epic_count_after_first)
        expect(award_emoji.where(awardable_type: 'Issue').count).to eq(issue_count_after_first)
      end
    end

    context 'when an epic has no award emoji' do
      let(:work_item4) do
        issues.create!(
          title: 'Issue 4',
          id: 10,
          iid: 4,
          namespace_id: group.id,
          work_item_type_id: epic_work_item_type_id
        )
      end

      let!(:epic3) do
        epics.create!(
          id: 11,
          iid: 6,
          group_id: group.id,
          author_id: user1.id,
          title: 'Epic 3',
          title_html: 'Epic 3',
          issue_id: work_item4.id
        )
      end

      it 'handles epics with no award emoji gracefully' do
        expect { perform_migration }.to change {
          award_emoji.where(awardable_type: 'Epic').count
        }.from(2).to(0)
        .and change {
          award_emoji.where(awardable_type: 'Issue').count
        }.from(2).to(4)

        expect(award_emoji.where(awardable_id: work_item4.id, awardable_type: 'Issue').count).to eq(0)
      end
    end
  end
end
