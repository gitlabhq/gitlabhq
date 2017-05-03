require 'spec_helper'

describe PruneOldEventsWorker do
  describe '#perform' do
    let!(:service_template) do
      PushoverService.create(
        template: true,
        properties: {
          device: 'MyDevice',
          sound: 'mic',
          priority: 4,
          api_key: '123456789'
        })
    end

    let!(:project) { create(:empty_project) }

    it 'creates services for projects' do
      expect { subject.perform }.to change { Service.count }.by(1)
    end

    it 'does not create the service if it exists already' do
      Service.build_from_template(project.id, service_template).save!

      expect { subject.perform }.not_to change { Service.count }
    end

    it 'creates the service containing the template attributes' do
      subject.perform

      service = Service.find_by(service_template.merge(project_id: project.id, template: false))

      expect(service).not_to be_nil
    end
  end
end
