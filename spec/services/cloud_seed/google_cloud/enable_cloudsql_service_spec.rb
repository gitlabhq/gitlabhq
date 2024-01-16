# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CloudSeed::GoogleCloud::EnableCloudsqlService, feature_category: :deployment_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:params) do
    {
      google_oauth2_token: 'mock-token',
      gcp_project_id: 'mock-gcp-project-id',
      environment_name: 'main'
    }
  end

  subject(:result) { described_class.new(project, user, params).execute }

  context 'when a project does not have any GCP_PROJECT_IDs configured' do
    it 'creates GCP_PROJECT_ID project var' do
      expect_next_instance_of(GoogleApi::CloudPlatform::Client) do |instance|
        expect(instance).to receive(:enable_cloud_sql_admin).with('mock-gcp-project-id')
        expect(instance).to receive(:enable_compute).with('mock-gcp-project-id')
        expect(instance).to receive(:enable_service_networking).with('mock-gcp-project-id')
      end

      expect(result[:status]).to eq(:success)
      expect(project.variables.count).to eq(1)
      expect(project.variables.first.key).to eq('GCP_PROJECT_ID')
      expect(project.variables.first.value).to eq('mock-gcp-project-id')
    end
  end

  context 'when a project has GCP_PROJECT_IDs configured' do
    before do
      project.variables.build(environment_scope: 'production', key: 'GCP_PROJECT_ID', value: 'prj-prod')
      project.variables.build(environment_scope: 'staging', key: 'GCP_PROJECT_ID', value: 'prj-staging')
      project.save!
    end

    after do
      project.variables.destroy_all # rubocop:disable Cop/DestroyAll
      project.save!
    end

    it 'enables cloudsql, compute and service networking Google APIs', :aggregate_failures do
      expect_next_instance_of(GoogleApi::CloudPlatform::Client) do |instance|
        expect(instance).to receive(:enable_cloud_sql_admin).with('mock-gcp-project-id')
        expect(instance).to receive(:enable_compute).with('mock-gcp-project-id')
        expect(instance).to receive(:enable_service_networking).with('mock-gcp-project-id')
        expect(instance).to receive(:enable_cloud_sql_admin).with('prj-prod')
        expect(instance).to receive(:enable_compute).with('prj-prod')
        expect(instance).to receive(:enable_service_networking).with('prj-prod')
        expect(instance).to receive(:enable_cloud_sql_admin).with('prj-staging')
        expect(instance).to receive(:enable_compute).with('prj-staging')
        expect(instance).to receive(:enable_service_networking).with('prj-staging')
      end

      expect(result[:status]).to eq(:success)
    end

    context 'when Google APIs raise an error' do
      it 'returns error result' do
        allow_next_instance_of(GoogleApi::CloudPlatform::Client) do |instance|
          allow(instance).to receive(:enable_cloud_sql_admin).with('mock-gcp-project-id')
          allow(instance).to receive(:enable_compute).with('mock-gcp-project-id')
          allow(instance).to receive(:enable_service_networking).with('mock-gcp-project-id')
          allow(instance).to receive(:enable_cloud_sql_admin).with('prj-prod')
          allow(instance).to receive(:enable_compute).with('prj-prod')
          allow(instance).to receive(:enable_service_networking).with('prj-prod')
          allow(instance).to receive(:enable_cloud_sql_admin).with('prj-staging')
          allow(instance).to receive(:enable_compute).with('prj-staging')
          allow(instance).to receive(:enable_service_networking).with('prj-staging')
                                                                .and_raise(Google::Apis::Error.new('error'))
        end

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq('error')
      end
    end
  end
end
