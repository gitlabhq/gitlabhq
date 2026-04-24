# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::DropPipelinesForBlockedUserWorker, feature_category: :continuous_integration do
  let_it_be_with_reload(:user) { create(:user) }

  subject(:worker) { described_class.new }

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [user.id] }
  end

  describe '#perform' do
    context 'when the user does not exist' do
      it 'does nothing' do
        expect(Ci::DropPipelinesAndDisableSchedulesForUserService).not_to receive(:new)

        worker.perform(non_existing_record_id)
      end
    end

    context 'when the user is not blocked' do
      it 'does nothing' do
        expect(Ci::DropPipelinesAndDisableSchedulesForUserService).not_to receive(:new)

        worker.perform(user.id)
      end
    end

    context 'when the user is blocked' do
      before do
        user.block!
      end

      it 'calls Ci::DropPipelinesAndDisableSchedulesForUserService with user_blocked reason' do
        service = instance_double(Ci::DropPipelinesAndDisableSchedulesForUserService)
        expect(Ci::DropPipelinesAndDisableSchedulesForUserService).to receive(:new).and_return(service)
        expect(service).to receive(:execute).with(
          user,
          reason: :user_blocked
        )

        worker.perform(user.id)
      end
    end
  end
end
