require 'spec_helper'

describe Projects::PropagateService, services: true do
  describe '.propagate!' do
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

    it 'creates services for projects' do
      expect { described_class.propagate!(service_template) }.
        to change { Service.count }.by(1)
    end

    it 'creates services for a project that has another service' do
      other_service = BambooService.create(
        template: true,
        active: true,
        properties: {
          bamboo_url: 'http://gitlab.com',
          username: 'mic',
          password: "password",
          build_key: 'build'
        }
      )

      Service.build_from_template(project.id, other_service).save!

      expect { described_class.propagate!(service_template) }.
        to change { Service.count }.by(1)
    end

    it 'does not create the service if it exists already' do
      other_service = BambooService.create(
        template: true,
        active: true,
        properties: {
          bamboo_url: 'http://gitlab.com',
          username: 'mic',
          password: "password",
          build_key: 'build'
        }
      )

      Service.build_from_template(project.id, service_template).save!
      Service.build_from_template(project.id, other_service).save!

      expect { described_class.propagate!(service_template) }.
        not_to change { Service.count }
    end

    it 'creates the service containing the template attributes' do
      described_class.propagate!(service_template)

      service = Service.find_by(type: service_template.type, template: false)

      expect(service.properties).to eq(service_template.properties)
    end
  end
end
