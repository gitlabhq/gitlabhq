# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthorizedProjectUpdate::EnqueueGroupMembersRefreshAuthorizedProjectsWorker, feature_category: :permissions do
  it 'has the `until_executed` deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
  end

  it 'has an option to reschedule once if deduplicated' do
    expect(described_class.get_deduplication_options).to include(
      { if_deduplicated: :reschedule_once, including_scheduled: true })
  end

  describe '#perform' do
    context 'when group exists' do
      let(:group) { create(:group) }

      it 'calls Group#refresh_members_authorized_projects' do
        allow(Group).to receive(:find_by_id).with(group.id).and_return(group)

        expect(group).to receive(:refresh_members_authorized_projects).with(
          priority: UserProjectAccessChangedService::LOW_PRIORITY,
          direct_members_only: false
        )

        described_class.new.perform(group.id)
      end

      it 'takes priority from params' do
        allow(Group).to receive(:find_by_id).with(group.id).and_return(group)

        expect(group).to receive(:refresh_members_authorized_projects).with(
          priority: UserProjectAccessChangedService::HIGH_PRIORITY,
          direct_members_only: false
        )

        described_class.new.perform(group.id, { 'priority' => UserProjectAccessChangedService::HIGH_PRIORITY.to_s })
      end

      it 'takes direct_members_only from params' do
        allow(Group).to receive(:find_by_id).with(group.id).and_return(group)

        expect(group).to receive(:refresh_members_authorized_projects).with(
          priority: UserProjectAccessChangedService::LOW_PRIORITY,
          direct_members_only: true
        )

        described_class.new.perform(group.id, { 'direct_members_only' => true })
      end
    end

    context 'when group is not found' do
      it 'does not raise errors' do
        expect { described_class.new.perform(non_existing_record_id) }.not_to raise_error
      end
    end
  end
end
