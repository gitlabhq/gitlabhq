# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::FixProjectsWithoutPrometheusService, :migration, schema: 2020_02_20_115023 do
  def service_params_for(project_id, params = {})
    {
      project_id: project_id,
      active: false,
      properties: '{}',
      type: 'PrometheusService',
      template: false,
      push_events: true,
      issues_events: true,
      merge_requests_events: true,
      tag_push_events: true,
      note_events: true,
      category: 'monitoring',
      default: false,
      wiki_page_events: true,
      pipeline_events: true,
      confidential_issues_events: true,
      commit_events: true,
      job_events: true,
      confidential_note_events: true,
      deployment_events: false
    }.merge(params)
  end

  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:services) { table(:services) }
  let(:clusters) { table(:clusters) }
  let(:cluster_groups) { table(:cluster_groups) }
  let(:clusters_applications_prometheus) { table(:clusters_applications_prometheus) }
  let(:namespace) { namespaces.create!(name: 'user', path: 'user') }
  let(:project) { projects.create!(namespace_id: namespace.id) }

  let(:application_statuses) do
    {
      errored: -1,
      installed: 3,
      updated: 5
    }
  end

  let(:cluster_types) do
    {
      instance_type: 1,
      group_type: 2,
      project_type: 3
    }
  end

  let(:columns) do
    %w(project_id active properties type template push_events
       issues_events merge_requests_events tag_push_events
       note_events category default wiki_page_events pipeline_events
       confidential_issues_events commit_events job_events
       confidential_note_events deployment_events)
  end

  describe '#perform' do
    shared_examples 'fix services entries state' do
      it 'is idempotent' do
        expect { subject.perform(project.id, project.id + 1) }.to change { services.order(:id).map { |row| row.attributes } }

        expect { subject.perform(project.id, project.id + 1) }.not_to change { services.order(:id).map { |row| row.attributes } }
      end

      context 'non prometheus services' do
        it 'does not change them' do
          other_type = 'SomeOtherService'
          services.create!(service_params_for(project.id, active: true, type: other_type))

          expect { subject.perform(project.id, project.id + 1) }.not_to change { services.where(type: other_type).order(:id).map { |row| row.attributes } }
        end
      end

      context 'prometheus integration services do not exist' do
        it 'creates missing services entries', :aggregate_failures do
          expect { subject.perform(project.id, project.id + 1) }.to change { services.count }.by(1)
          expect([service_params_for(project.id, active: true)]).to eq services.order(:id).map { |row| row.attributes.slice(*columns).symbolize_keys }
        end

        context 'template is present for prometheus services' do
          it 'creates missing services entries', :aggregate_failures do
            services.create!(service_params_for(nil, template: true, properties: { 'from_template' => true }.to_json))

            expect { subject.perform(project.id, project.id + 1) }.to change { services.count }.by(1)
            updated_rows = services.where(template: false).order(:id).map { |row| row.attributes.slice(*columns).symbolize_keys }
            expect([service_params_for(project.id, active: true, properties: { 'from_template' => true }.to_json)]).to eq updated_rows
          end
        end
      end

      context 'prometheus integration services exist' do
        context 'in active state' do
          it 'does not change them' do
            services.create!(service_params_for(project.id, active: true))

            expect { subject.perform(project.id, project.id + 1) }.not_to change { services.order(:id).map { |row| row.attributes } }
          end
        end

        context 'not in active state' do
          it 'sets active attribute to true' do
            service = services.create!(service_params_for(project.id, active: false))

            expect { subject.perform(project.id, project.id + 1) }.to change { service.reload.active? }.from(false).to(true)
          end

          context 'prometheus services are configured manually ' do
            it 'does not change them' do
              properties = '{"api_url":"http://test.dev","manual_configuration":"1"}'
              services.create!(service_params_for(project.id, properties: properties, active: false))

              expect { subject.perform(project.id, project.id + 1) }.not_to change { services.order(:id).map { |row| row.attributes } }
            end
          end
        end
      end
    end

    context 'k8s cluster shared on instance level' do
      let(:cluster) { clusters.create!(name: 'cluster', cluster_type: cluster_types[:instance_type]) }

      context 'with installed prometheus application' do
        before do
          clusters_applications_prometheus.create!(cluster_id: cluster.id, status: application_statuses[:installed], version: '123')
        end

        it_behaves_like 'fix services entries state'
      end

      context 'with updated prometheus application' do
        before do
          clusters_applications_prometheus.create!(cluster_id: cluster.id, status: application_statuses[:updated], version: '123')
        end

        it_behaves_like 'fix services entries state'
      end

      context 'with errored prometheus application' do
        before do
          clusters_applications_prometheus.create!(cluster_id: cluster.id, status: application_statuses[:errored], version: '123')
        end

        it 'does not change services entries' do
          expect { subject.perform(project.id, project.id + 1) }.not_to change { services.order(:id).map { |row| row.attributes } }
        end
      end
    end

    context 'k8s cluster shared on group level' do
      let(:cluster) { clusters.create!(name: 'cluster', cluster_type: cluster_types[:group_type]) }

      before do
        cluster_groups.create!(cluster_id: cluster.id, group_id: project.namespace_id)
      end

      context 'with installed prometheus application' do
        before do
          clusters_applications_prometheus.create!(cluster_id: cluster.id, status: application_statuses[:installed], version: '123')
        end

        it_behaves_like 'fix services entries state'

        context 'second k8s cluster without application available' do
          let(:namespace_2) { namespaces.create!(name: 'namespace2', path: 'namespace2') }
          let(:project_2) { projects.create!(namespace_id: namespace_2.id) }

          before do
            cluster_2 = clusters.create!(name: 'cluster2', cluster_type: cluster_types[:group_type])
            cluster_groups.create!(cluster_id: cluster_2.id, group_id: project_2.namespace_id)
          end

          it 'changed only affected services entries' do
            expect { subject.perform(project.id, project_2.id + 1) }.to change { services.count }.by(1)
            expect([service_params_for(project.id, active: true)]).to eq services.order(:id).map { |row| row.attributes.slice(*columns).symbolize_keys }
          end
        end
      end

      context 'with updated prometheus application' do
        before do
          clusters_applications_prometheus.create!(cluster_id: cluster.id, status: application_statuses[:updated], version: '123')
        end

        it_behaves_like 'fix services entries state'
      end

      context 'with errored prometheus application' do
        before do
          clusters_applications_prometheus.create!(cluster_id: cluster.id, status: application_statuses[:errored], version: '123')
        end

        it 'does not change services entries' do
          expect { subject.perform(project.id, project.id + 1) }.not_to change { services.order(:id).map { |row| row.attributes } }
        end
      end

      context 'with missing prometheus application' do
        it 'does not change services entries' do
          expect { subject.perform(project.id, project.id + 1) }.not_to change { services.order(:id).map { |row| row.attributes } }
        end

        context 'with inactive service' do
          it 'does not change services entries' do
            services.create!(service_params_for(project.id))

            expect { subject.perform(project.id, project.id + 1) }.not_to change { services.order(:id).map { |row| row.attributes } }
          end
        end
      end
    end

    context 'k8s cluster for single project' do
      let(:cluster) { clusters.create!(name: 'cluster', cluster_type: cluster_types[:project_type]) }
      let(:cluster_projects) { table(:cluster_projects) }

      context 'with installed prometheus application' do
        before do
          cluster_projects.create!(cluster_id: cluster.id, project_id: project.id)
          clusters_applications_prometheus.create!(cluster_id: cluster.id, status: application_statuses[:installed], version: '123')
        end

        it 'does not change services entries' do
          expect { subject.perform(project.id, project.id + 1) }.not_to change { services.order(:id).map { |row| row.attributes } }
        end
      end
    end
  end
end
