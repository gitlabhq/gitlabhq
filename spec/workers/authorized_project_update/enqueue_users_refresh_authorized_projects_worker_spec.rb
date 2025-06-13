# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthorizedProjectUpdate::EnqueueUsersRefreshAuthorizedProjectsWorker, feature_category: :permissions do
  describe '#perform' do
    let_it_be(:user_ids) { [1, 2, 3] }

    subject(:execute) {  described_class.new.perform(user_ids) }

    it 'calls UserProjectAccessChangedService' do
      expect_next_instance_of(UserProjectAccessChangedService, user_ids) do |service|
        expect(service).to receive(:execute).with(
          priority: UserProjectAccessChangedService::LOW_PRIORITY
        )
      end

      execute
    end

    context 'with an empty array of user_ids' do
      let(:user_ids) { [] }

      it 'does not call UserProjectAccessChangedService' do
        expect(UserProjectAccessChangedService).not_to receive(:new)

        execute
      end
    end
  end
end
