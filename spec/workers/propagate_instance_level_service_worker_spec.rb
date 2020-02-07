# frozen_string_literal: true

require 'spec_helper'

describe PropagateInstanceLevelServiceWorker do
  include ExclusiveLeaseHelpers

  describe '#perform' do
    it 'calls the propagate service with the instance level service' do
      instance_level_service = PushoverService.create(
        instance: true,
        active: true,
        properties: {
          device: 'MyDevice',
          sound: 'mic',
          priority: 4,
          user_key: 'asdf',
          api_key: '123456789'
        })

      stub_exclusive_lease("propagate_instance_level_service_worker:#{instance_level_service.id}",
        timeout: PropagateInstanceLevelServiceWorker::LEASE_TIMEOUT)

      expect(Projects::PropagateInstanceLevelService)
        .to receive(:propagate)
        .with(instance_level_service)

      subject.perform(instance_level_service.id)
    end
  end
end
