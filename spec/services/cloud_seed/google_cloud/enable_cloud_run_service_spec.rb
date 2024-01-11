# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CloudSeed::GoogleCloud::EnableCloudRunService, feature_category: :deployment_management do
  describe 'when a project does not have any gcp projects' do
    let_it_be(:project) { create(:project) }

    it 'returns error' do
      result = described_class.new(project).execute

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('No GCP projects found. Configure a service account or GCP_PROJECT_ID ci variable.')
    end
  end

  describe 'when a project has 3 gcp projects' do
    let_it_be(:project) { create(:project) }

    before do
      project.variables.build(environment_scope: 'production', key: 'GCP_PROJECT_ID', value: 'prj-prod')
      project.variables.build(environment_scope: 'staging', key: 'GCP_PROJECT_ID', value: 'prj-staging')
      project.save!
    end

    it 'enables cloud run, artifacts registry and cloud build', :aggregate_failures do
      expect_next_instance_of(GoogleApi::CloudPlatform::Client) do |instance|
        expect(instance).to receive(:enable_cloud_run).with('prj-prod')
        expect(instance).to receive(:enable_artifacts_registry).with('prj-prod')
        expect(instance).to receive(:enable_cloud_build).with('prj-prod')
        expect(instance).to receive(:enable_cloud_run).with('prj-staging')
        expect(instance).to receive(:enable_artifacts_registry).with('prj-staging')
        expect(instance).to receive(:enable_cloud_build).with('prj-staging')
      end

      result = described_class.new(project).execute

      expect(result[:status]).to eq(:success)
    end
  end
end
