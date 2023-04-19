# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::DeleteExpiredEventsWorker, feature_category: :deployment_management do
  let(:agent) { create(:cluster_agent) }

  describe '#perform' do
    let(:agent_id) { agent.id }
    let(:deletion_service) { double(execute: true) }

    subject { described_class.new.perform(agent_id) }

    it 'calls the deletion service' do
      expect(deletion_service).to receive(:execute).once
      expect(Clusters::Agents::DeleteExpiredEventsService).to receive(:new)
        .with(agent).and_return(deletion_service)

      subject
    end

    context 'agent no longer exists' do
      let(:agent_id) { -1 }

      it 'completes without raising an error' do
        expect { subject }.not_to raise_error
      end
    end
  end
end
