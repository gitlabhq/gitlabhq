# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillEpicSubscriptionToWorkItems, feature_category: :portfolio_management do
  let(:subscriptions) { table(:subscriptions) }
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

  let(:another_user) do
    users.create!(
      username: 'another_user',
      email: 'another@example.com',
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let(:epic_work_item_type_id) { 8 }

  let!(:work_item1) do
    issues.create!(
      id: 1,
      title: 'Work Item 1',
      iid: 1,
      namespace_id: group.id,
      work_item_type_id: epic_work_item_type_id
    )
  end

  let!(:work_item2) do
    issues.create!(
      id: 2,
      title: 'Work Item 2',
      iid: 2,
      namespace_id: group.id,
      work_item_type_id: epic_work_item_type_id
    )
  end

  let!(:epic1) do
    epics.create!(
      id: 11,
      iid: 1,
      group_id: group.id,
      author_id: user.id,
      title: 'Epic 1',
      title_html: 'Epic 1',
      issue_id: work_item1.id
    )
  end

  let!(:epic2) do
    epics.create!(
      id: 12,
      iid: 2,
      group_id: group.id,
      author_id: user.id,
      title: 'Epic 2',
      title_html: 'Epic 2',
      issue_id: work_item2.id
    )
  end

  # A subscription pointing to epic1 with subscribable_type 'Epic'
  let!(:epic1_subscription) do
    subscriptions.create!(
      subscribable_id: epic1.id,
      subscribable_type: 'Epic',
      user_id: user.id,
      subscribed: true
    )
  end

  # A subscription pointing to epic2 with subscribable_type 'Epic'
  let!(:epic2_subscription) do
    subscriptions.create!(
      subscribable_id: epic2.id,
      subscribable_type: 'Epic',
      user_id: user.id,
      subscribed: true
    )
  end

  # A subscription already pointing to the work item (should not be changed)
  let!(:work_item1_subscription) do
    subscriptions.create!(
      subscribable_id: work_item1.id,
      subscribable_type: 'Issue',
      user_id: user.id,
      subscribed: false
    )
  end

  # A subscription pointed to another user, doesn't have corresponded epic (should not be changed)
  let!(:work_item1_subscription_another_user) do
    subscriptions.create!(
      subscribable_id: work_item1.id,
      subscribable_type: 'Issue',
      user_id: another_user.id,
      subscribed: false
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

    it 'migrates epic subscriptions to point to the corresponding work item without duplicates' do
      expect { perform_migration }.to change {
        subscriptions.where(subscribable_type: 'Epic').count
      }.from(2).to(0)
      .and change {
        subscriptions.where(subscribable_type: 'Issue').count
      }.from(2).to(3)

      expect(subscriptions.find(work_item1_subscription.id)).to have_attributes(
        subscribable_type: 'Issue',
        subscribable_id: work_item1.id,
        user_id: user.id
      )

      expect(subscriptions.find(work_item1_subscription_another_user.id)).to have_attributes(
        subscribable_type: 'Issue',
        subscribable_id: work_item1.id,
        user_id: another_user.id
      )

      expect(subscriptions.find(epic2_subscription.id)).to have_attributes(
        subscribable_type: 'Issue',
        subscribable_id: work_item2.id
      )
    end

    it 'removes duplicate and leaves a newer entry' do
      subscriptions.create!(
        subscribable_id: work_item2.id,
        subscribable_type: 'Issue',
        user_id: user.id,
        subscribed: false
      )
      epic2_subscription.update_column(:updated_at, 1.minute.from_now)

      perform_migration

      expect(subscriptions.find(epic2_subscription.id)).to have_attributes(
        subscribable_type: 'Issue',
        subscribable_id: work_item2.id,
        subscribed: true
      )
    end

    context 'when there are more than SUBSCRIPTIONS_BATCH_SIZE subscriptions for an epic' do
      let(:extra_users) do
        (1..described_class::SUBSCRIPTIONS_BATCH_SIZE).map do |i|
          users.create!(
            username: "extra_user_#{i}",
            email: "extra_user_#{i}@example.com",
            projects_limit: 10,
            organization_id: organization.id
          )
        end
      end

      before do
        stub_const("#{described_class}::SUBSCRIPTIONS_BATCH_SIZE", 2)

        extra_users.each do |extra_user|
          subscriptions.create!(
            subscribable_id: epic1.id,
            subscribable_type: 'Epic',
            user_id: extra_user.id,
            subscribed: true
          )
        end
      end

      it 'processes all subscriptions across multiple loop iterations' do
        total_epic1_subscriptions = subscriptions.where(subscribable_id: epic1.id, subscribable_type: 'Epic').count

        expect(total_epic1_subscriptions).to be > described_class::SUBSCRIPTIONS_BATCH_SIZE

        perform_migration

        expect(subscriptions.where(subscribable_type: 'Epic').count).to eq(0)
        expect(subscriptions.where(subscribable_id: work_item1.id, subscribable_type: 'Issue').count)
          .to eq(total_epic1_subscriptions + 1)
      end
    end
  end
end
