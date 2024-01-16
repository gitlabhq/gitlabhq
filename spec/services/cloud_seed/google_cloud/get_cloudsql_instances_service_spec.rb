# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CloudSeed::GoogleCloud::GetCloudsqlInstancesService, feature_category: :deployment_management do
  let(:service) { described_class.new(project) }
  let(:project) { create(:project) }

  context 'when project has no registered cloud sql instances' do
    it 'result is empty' do
      expect(service.execute.length).to eq(0)
    end
  end

  context 'when project has registered cloud sql instance' do
    before do
      keys = %w[
        GCP_PROJECT_ID
        GCP_CLOUDSQL_INSTANCE_NAME
        GCP_CLOUDSQL_CONNECTION_NAME
        GCP_CLOUDSQL_PRIMARY_IP_ADDRESS
        GCP_CLOUDSQL_VERSION
        GCP_CLOUDSQL_DATABASE_NAME
        GCP_CLOUDSQL_DATABASE_USER
        GCP_CLOUDSQL_DATABASE_PASS
      ]

      envs = %w[
        *
        STG
        PRD
      ]

      keys.each do |key|
        envs.each do |env|
          project.variables.build(protected: false, environment_scope: env, key: key, value: "value-#{key}-#{env}")
        end
      end
    end

    it 'result is grouped by environment', :aggregate_failures do
      expect(service.execute).to contain_exactly(
        {
          ref: '*',
          gcp_project: 'value-GCP_PROJECT_ID-*',
          instance_name: 'value-GCP_CLOUDSQL_INSTANCE_NAME-*',
          version: 'value-GCP_CLOUDSQL_VERSION-*'
        },
        {
          ref: 'STG',
          gcp_project: 'value-GCP_PROJECT_ID-STG',
          instance_name: 'value-GCP_CLOUDSQL_INSTANCE_NAME-STG',
          version: 'value-GCP_CLOUDSQL_VERSION-STG'
        },
        {
          ref: 'PRD',
          gcp_project: 'value-GCP_PROJECT_ID-PRD',
          instance_name: 'value-GCP_CLOUDSQL_INSTANCE_NAME-PRD',
          version: 'value-GCP_CLOUDSQL_VERSION-PRD'
        }
      )
    end
  end
end
