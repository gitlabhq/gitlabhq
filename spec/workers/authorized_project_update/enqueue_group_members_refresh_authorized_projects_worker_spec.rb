# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthorizedProjectUpdate::EnqueueGroupMembersRefreshAuthorizedProjectsWorker, feature_category: :permissions do
  describe '#perform' do
    context 'when group exists' do
      let(:group) { create(:group) }

      it 'calls Group#refresh_members_authorized_projects' do
        allow(Group).to receive(:find_by_id).with(group.id).and_return(group)

        expect(group).to receive(:refresh_members_authorized_projects).with(
          priority: UserProjectAccessChangedService::LOW_PRIORITY
        )

        described_class.new.perform(group.id)
      end
    end

    context 'when group is not found' do
      it 'does not raise errors' do
        expect { described_class.new.perform(non_existing_record_id) }.not_to raise_error
      end
    end
  end
end
