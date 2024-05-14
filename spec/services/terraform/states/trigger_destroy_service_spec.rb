# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Terraform::States::TriggerDestroyService, feature_category: :infrastructure_as_code do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, maintainer_of: project) }

  describe '#execute', :aggregate_failures do
    let_it_be(:state) { create(:terraform_state, project: project) }

    let(:service) { described_class.new(state, current_user: user) }

    subject { service.execute }

    it 'marks the state as deleted and schedules a cleanup worker' do
      expect(Terraform::States::DestroyWorker).to receive(:perform_async).with(state.id).once

      expect(subject).to be_success
      expect(state.deleted_at).to be_like_time(Time.current)
    end

    context 'within a database transaction' do
      subject { state.with_lock { service.execute } }

      it 'does not raise an EnqueueFromTransactionError' do
        expect { subject }.not_to raise_error
        expect(state.deleted_at).to be_like_time(Time.current)
      end
    end

    shared_examples 'unable to delete state' do
      it 'does not modify the state' do
        expect(Terraform::States::DestroyWorker).not_to receive(:perform_async)

        expect { subject }.not_to change(state, :deleted_at)
        expect(subject).to be_error
        expect(subject.message).to eq(message)
      end
    end

    context 'user does not have permission' do
      let(:user) { create(:user, developer_of: project) }
      let(:message) { 'You have insufficient permissions to delete this state' }

      include_examples 'unable to delete state'
    end

    context 'state is locked' do
      let(:state) { create(:terraform_state, :locked, project: project) }
      let(:message) { 'Cannot remove a locked state' }

      include_examples 'unable to delete state'
    end
  end
end
