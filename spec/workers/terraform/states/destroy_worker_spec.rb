# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Terraform::States::DestroyWorker, feature_category: :infrastructure_as_code do
  let(:state) { create(:terraform_state) }

  describe '#perform' do
    let(:state_id) { state.id }
    let(:deletion_service) { instance_double(Terraform::States::DestroyService, execute: true) }

    subject { described_class.new.perform(state_id) }

    it 'calls the deletion service' do
      expect(deletion_service).to receive(:execute).once
      expect(Terraform::States::DestroyService).to receive(:new)
        .with(state).and_return(deletion_service)

      subject
    end

    context 'state no longer exists' do
      let(:state_id) { -1 }

      it 'completes without error' do
        expect { subject }.not_to raise_error
      end
    end
  end
end
