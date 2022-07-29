# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GoogleCloud::EnableCloudsqlService do
  let_it_be(:project) { create(:project) }

  subject(:result) { described_class.new(project).execute }

  context 'when a project does not have any GCP_PROJECT_IDs configured' do
    it 'returns error' do
      message = 'No GCP projects found. Configure a service account or GCP_PROJECT_ID CI variable.'

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq(message)
    end
  end

  context 'when a project has GCP_PROJECT_IDs configured' do
    before do
      project.variables.build(environment_scope: 'production', key: 'GCP_PROJECT_ID', value: 'prj-prod')
      project.variables.build(environment_scope: 'staging', key: 'GCP_PROJECT_ID', value: 'prj-staging')
      project.save!
    end

    it 'enables cloudsql, compute and service networking Google APIs', :aggregate_failures do
      expect_next_instance_of(GoogleApi::CloudPlatform::Client) do |instance|
        expect(instance).to receive(:enable_cloud_sql_admin).with('prj-prod')
        expect(instance).to receive(:enable_compute).with('prj-prod')
        expect(instance).to receive(:enable_service_networking).with('prj-prod')
        expect(instance).to receive(:enable_cloud_sql_admin).with('prj-staging')
        expect(instance).to receive(:enable_compute).with('prj-staging')
        expect(instance).to receive(:enable_service_networking).with('prj-staging')
      end

      expect(result[:status]).to eq(:success)
    end
  end
end
