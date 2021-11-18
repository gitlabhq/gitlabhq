# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GoogleCloud::ServiceAccountsService do
  let_it_be(:project) { create(:project) }

  let(:service) { described_class.new(project) }

  describe 'find_for_project' do
    context 'when a project does not have GCP service account vars' do
      before do
        project.variables.build(key: 'blah', value: 'foo', environment_scope: 'world')
        project.save!
      end

      it 'returns an empty list' do
        expect(service.find_for_project.length).to eq(0)
      end
    end

    context 'when a project has GCP service account ci vars' do
      before do
        project.variables.build(environment_scope: '*', key: 'GCP_PROJECT_ID', value: 'prj1')
        project.variables.build(environment_scope: '*', key: 'GCP_SERVICE_ACCOUNT_KEY', value: 'mock')
        project.variables.build(environment_scope: 'staging', key: 'GCP_PROJECT_ID', value: 'prj2')
        project.variables.build(environment_scope: 'staging', key: 'GCP_SERVICE_ACCOUNT', value: 'mock')
        project.variables.build(environment_scope: 'production', key: 'GCP_PROJECT_ID', value: 'prj3')
        project.variables.build(environment_scope: 'production', key: 'GCP_SERVICE_ACCOUNT', value: 'mock')
        project.variables.build(environment_scope: 'production', key: 'GCP_SERVICE_ACCOUNT_KEY', value: 'mock')
        project.save!
      end

      it 'returns a list of service accounts' do
        list = service.find_for_project

        aggregate_failures 'testing list of service accounts' do
          expect(list.length).to eq(3)

          expect(list.first[:environment]).to eq('*')
          expect(list.first[:gcp_project]).to eq('prj1')
          expect(list.first[:service_account_exists]).to eq(false)
          expect(list.first[:service_account_key_exists]).to eq(true)

          expect(list.second[:environment]).to eq('staging')
          expect(list.second[:gcp_project]).to eq('prj2')
          expect(list.second[:service_account_exists]).to eq(true)
          expect(list.second[:service_account_key_exists]).to eq(false)

          expect(list.third[:environment]).to eq('production')
          expect(list.third[:gcp_project]).to eq('prj3')
          expect(list.third[:service_account_exists]).to eq(true)
          expect(list.third[:service_account_key_exists]).to eq(true)
        end
      end
    end
  end
end
