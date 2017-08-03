require 'spec_helper'

describe Projects::PropagateServiceTemplate do
  describe '.propagate' do
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

    let!(:project) { create(:project) }

    it 'creates services for projects' do
      expect(project.pushover_service).to be_nil

      described_class.propagate(service_template)

      expect(project.reload.pushover_service).to be_present
    end

    it 'creates services for a project that has another service' do
      BambooService.create(
        template: true,
        active: true,
        project: project,
        properties: {
          bamboo_url: 'http://gitlab.com',
          username: 'mic',
          password: "password",
          build_key: 'build'
        }
      )

      expect(project.pushover_service).to be_nil

      described_class.propagate(service_template)

      expect(project.reload.pushover_service).to be_present
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

      expect { described_class.propagate(service_template) }
        .not_to change { Service.count }
    end

    it 'creates the service containing the template attributes' do
      described_class.propagate(service_template)

      expect(project.pushover_service.properties).to eq(service_template.properties)
    end

    describe 'bulk update' do
      let(:project_total) { 5 }

      before do
        stub_const 'Projects::PropagateServiceTemplate::BATCH_SIZE', 3

        project_total.times { create(:project) }

        described_class.propagate(service_template)
      end

      it 'creates services for all projects' do
        expect(Service.all.reload.count).to eq(project_total + 2)
      end
    end

    describe 'external tracker' do
      it 'updates the project external tracker' do
        service_template.update!(category: 'issue_tracker', default: false)

        expect { described_class.propagate(service_template) }
          .to change { project.reload.has_external_issue_tracker }.to(true)
      end
    end

    describe 'external wiki' do
      it 'updates the project external tracker' do
        service_template.update!(type: 'ExternalWikiService')

        expect { described_class.propagate(service_template) }
          .to change { project.reload.has_external_wiki }.to(true)
      end
    end
  end
end
