# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PropagateServiceTemplateWorker do
  include ExclusiveLeaseHelpers

  describe '#perform' do
    it 'calls the propagate service with the template' do
      template = Integrations::Pushover.create!(
        template: true,
        active: true,
        properties: {
          device: 'MyDevice',
          sound: 'mic',
          priority: 4,
          user_key: 'asdf',
          api_key: '123456789'
        })

      stub_exclusive_lease("propagate_service_template_worker:#{template.id}",
        timeout: PropagateServiceTemplateWorker::LEASE_TIMEOUT)

      expect(Admin::PropagateServiceTemplate)
        .to receive(:propagate)
        .with(template)

      subject.perform(template.id)
    end
  end
end
