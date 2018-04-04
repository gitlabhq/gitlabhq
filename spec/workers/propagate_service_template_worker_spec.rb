require 'spec_helper'

describe PropagateServiceTemplateWorker do
  include ExclusiveLeaseHelpers

  describe '#perform' do
    it 'calls the propagate service with the template' do
      template = PushoverService.create(
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

      expect(Projects::PropagateServiceTemplate)
        .to receive(:propagate)
        .with(template)

      subject.perform(template.id)
    end

    it 'silently ignores error when lease could not be obtained' do
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return(nil)

      subject.perform(service_template.id)
    end
  end
end
