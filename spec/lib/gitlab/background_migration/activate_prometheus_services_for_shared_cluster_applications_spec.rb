# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::ActivatePrometheusServicesForSharedClusterApplications, :migration, schema: 2019_12_20_102807 do
  include MigrationHelpers::PrometheusServiceHelpers

  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:services) { table(:services) }
  let(:namespace) { namespaces.create(name: 'user', path: 'user') }
  let(:project) { projects.create(namespace_id: namespace.id) }

  let(:columns) do
    %w(project_id active properties type template push_events
       issues_events merge_requests_events tag_push_events
       note_events category default wiki_page_events pipeline_events
       confidential_issues_events commit_events job_events
       confidential_note_events deployment_events)
  end

  describe '#perform' do
    it 'is idempotent' do
      expect { subject.perform(project.id) }.to change { services.order(:id).map { |row| row.attributes } }

      expect { subject.perform(project.id) }.not_to change { services.order(:id).map { |row| row.attributes } }
    end

    context 'non prometheus services' do
      it 'does not change them' do
        other_type = 'SomeOtherService'
        services.create(service_params_for(project.id, active: true, type: other_type))

        expect { subject.perform(project.id) }.not_to change { services.where(type: other_type).order(:id).map { |row| row.attributes } }
      end
    end

    context 'prometheus services are configured manually ' do
      it 'does not change them' do
        properties = '{"api_url":"http://test.dev","manual_configuration":"1"}'
        services.create(service_params_for(project.id, properties: properties, active: false))

        expect { subject.perform(project.id) }.not_to change { services.order(:id).map { |row| row.attributes } }
      end
    end

    context 'prometheus integration services do not exist' do
      it 'creates missing services entries' do
        subject.perform(project.id)

        rows = services.order(:id).map { |row| row.attributes.slice(*columns).symbolize_keys }

        expect([service_params_for(project.id, active: true)]).to eq rows
      end
    end

    context 'prometheus integration services exist' do
      context 'in active state' do
        it 'does not change them' do
          services.create(service_params_for(project.id, active: true))

          expect { subject.perform(project.id) }.not_to change { services.order(:id).map { |row| row.attributes } }
        end
      end

      context 'not in active state' do
        it 'sets active attribute to true' do
          service = services.create(service_params_for(project.id))

          expect { subject.perform(project.id) }.to change { service.reload.active? }.from(false).to(true)
        end
      end
    end
  end
end
