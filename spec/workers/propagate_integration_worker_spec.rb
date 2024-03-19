# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PropagateIntegrationWorker, feature_category: :integrations do
  shared_examples 'propagated integration' do
    it 'calls the propagate service with the integration' do
      expect_next_instance_of(Integrations::PropagateService, integration) do |service|
        expect(service).to receive(:execute)
      end

      subject.perform(integration.id)
    end
  end

  shared_examples 'not-propagated integration' do
    it 'does not call the propagate service' do
      expect(Integrations::PropagateService).not_to receive(:new)

      subject.perform(integration.id)
    end
  end

  describe '#perform' do
    context 'with integration on instance level' do
      let(:integration) { create(:pushover_integration, :instance) }

      it_behaves_like 'propagated integration'
    end

    context 'with integration on group level' do
      let(:integration) { create(:pushover_integration, :group) }

      it_behaves_like 'propagated integration'
    end

    context 'with integration on project level' do
      let(:integration) { create(:pushover_integration) }

      it_behaves_like 'not-propagated integration'
    end

    context 'when integration does not exist' do
      let(:integration) { build(:pushover_integration) }

      it_behaves_like 'not-propagated integration'
    end
  end
end
