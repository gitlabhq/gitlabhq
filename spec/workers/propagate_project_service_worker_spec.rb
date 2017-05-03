require 'spec_helper'

describe PropagateProjectServiceWorker do
  describe '#perform' do
    let!(:service_template) do
      PushoverService.create(
        template: true,
        active: true,
        properties: {
          device: 'MyDevice',
          sound: 'mic',
          priority: 4,
          user_key: 'asdf',
          api_key: '123456789'
        })
    end

    let!(:project) { create(:empty_project) }

    before do
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).
        and_return(true)
    end

    it 'creates services for projects' do
      expect { subject.perform(service_template.id) }.to change { Service.count }.by(1)
    end

    it 'does not create the service if it exists already' do
      Service.build_from_template(project.id, service_template).save!

      expect { subject.perform(service_template.id) }.not_to change { Service.count }
    end

    it 'creates the service containing the template attributes' do
      subject.perform(service_template.id)

      service = Service.find_by(type: service_template.type, template: false)

      expect(service.properties).to eq(service_template.properties)
    end
  end
end
