# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PropagateIntegrationWorker do
  describe '#perform' do
    let(:integration) do
      PushoverService.create!(
        template: true,
        active: true,
        device: 'MyDevice',
        sound: 'mic',
        priority: 4,
        user_key: 'asdf',
        api_key: '123456789'
      )
    end

    it 'calls the propagate service with the integration' do
      expect(Admin::PropagateIntegrationService).to receive(:propagate).with(integration)

      subject.perform(integration.id)
    end

    it 'ignores overwrite parameter from previous version' do
      expect(Admin::PropagateIntegrationService).to receive(:propagate).with(integration)

      subject.perform(integration.id, true)
    end
  end
end
