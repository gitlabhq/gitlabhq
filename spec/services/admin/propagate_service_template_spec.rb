# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::PropagateServiceTemplate do
  describe '.propagate' do
    let_it_be(:project) { create(:project) }

    let!(:service_template) do
      Integrations::Pushover.create!(
        template: true,
        active: true,
        push_events: false,
        properties: {
          device: 'MyDevice',
          sound: 'mic',
          priority: 4,
          user_key: 'asdf',
          api_key: '123456789'
        }
      )
    end

    it 'calls to PropagateIntegrationProjectWorker' do
      expect(PropagateIntegrationProjectWorker).to receive(:perform_async)
        .with(service_template.id, project.id, project.id)

      described_class.propagate(service_template)
    end

    context 'with a project that has another service' do
      before do
        Integrations::Bamboo.create!(
          active: true,
          project: project,
          properties: {
            bamboo_url: 'http://gitlab.com',
            username: 'mic',
            password: 'password',
            build_key: 'build'
          }
        )
      end

      it 'calls to PropagateIntegrationProjectWorker' do
        expect(PropagateIntegrationProjectWorker).to receive(:perform_async)
          .with(service_template.id, project.id, project.id)

        described_class.propagate(service_template)
      end
    end

    it 'does not create the service if it exists already' do
      Integration.build_from_integration(service_template, project_id: project.id).save!

      expect { described_class.propagate(service_template) }
        .not_to change { Integration.count }
    end
  end
end
