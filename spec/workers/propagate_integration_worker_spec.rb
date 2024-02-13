# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PropagateIntegrationWorker, feature_category: :integrations do
  describe '#perform' do
    let(:project) { create(:project) }
    let(:integration) do
      Integrations::Pushover.create!(
        project: project,
        active: true,
        device: 'MyDevice',
        sound: 'mic',
        priority: 4,
        user_key: 'asdf',
        api_key: '123456789'
      )
    end

    it 'calls the propagate service with the integration' do
      expect_next_instance_of(Integrations::PropagateService, integration) do |service|
        expect(service).to receive(:execute)
      end

      subject.perform(integration.id)
    end

    it 'does nothing when the integration does not exist' do
      expect(Integrations::PropagateService).not_to receive(:new)

      subject.perform(non_existing_record_id)
    end
  end
end
