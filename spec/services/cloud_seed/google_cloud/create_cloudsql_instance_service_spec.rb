# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CloudSeed::GoogleCloud::CreateCloudsqlInstanceService, feature_category: :deployment_management do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:gcp_project_id) { 'gcp_project_120' }
  let(:environment_name) { 'test_env_42' }
  let(:database_version) { 'POSTGRES_8000' }
  let(:tier) { 'REIT_TIER' }
  let(:service) do
    described_class.new(project, user, {
      gcp_project_id: gcp_project_id,
      environment_name: environment_name,
      database_version: database_version,
      tier: tier
    })
  end

  describe '#execute' do
    before do
      allow_next_instance_of(::Ci::VariablesFinder) do |variable_finder|
        allow(variable_finder).to receive(:execute).and_return([])
      end
    end

    it 'triggers creation of a cloudsql instance' do
      expect_next_instance_of(GoogleApi::CloudPlatform::Client) do |client|
        expected_instance_name = "gitlab-#{project.id}-postgres-8000-test-env-42"
        expect(client).to receive(:create_cloudsql_instance).with(
          gcp_project_id,
          expected_instance_name,
          String,
          database_version,
          'us-east1',
          tier
        )
      end

      result = service.execute
      expect(result[:status]).to be(:success)
    end

    it 'triggers worker to manage cloudsql instance creation operation results' do
      expect_next_instance_of(GoogleApi::CloudPlatform::Client) do |client|
        expect(client).to receive(:create_cloudsql_instance)
      end

      expect(GoogleCloud::CreateCloudsqlInstanceWorker).to receive(:perform_in)

      result = service.execute
      expect(result[:status]).to be(:success)
    end

    context 'when google APIs fail' do
      it 'returns error' do
        expect_next_instance_of(GoogleApi::CloudPlatform::Client) do |client|
          expect(client).to receive(:create_cloudsql_instance).and_raise(Google::Apis::Error.new('mock-error'))
        end

        result = service.execute
        expect(result[:status]).to eq(:error)
      end
    end

    context 'when project has GCP_REGION defined' do
      let(:gcp_region) { instance_double(::Ci::Variable, key: 'GCP_REGION', value: 'user-defined-region') }

      before do
        allow_next_instance_of(::Ci::VariablesFinder) do |variable_finder|
          allow(variable_finder).to receive(:execute).and_return([gcp_region])
        end
      end

      it 'uses defined region' do
        expect_next_instance_of(GoogleApi::CloudPlatform::Client) do |client|
          expect(client).to receive(:create_cloudsql_instance).with(
            gcp_project_id,
            String,
            String,
            database_version,
            'user-defined-region',
            tier
          )
        end

        service.execute
      end
    end
  end
end
