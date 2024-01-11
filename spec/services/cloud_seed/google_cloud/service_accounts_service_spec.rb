# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CloudSeed::GoogleCloud::ServiceAccountsService, feature_category: :deployment_management do
  let(:service) { described_class.new(project) }

  describe 'find_for_project' do
    let_it_be(:project) { create(:project) }

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
        project.variables.build(protected: true, environment_scope: '*', key: 'GCP_PROJECT_ID', value: 'prj1')
        project.variables.build(protected: true, environment_scope: '*', key: 'GCP_SERVICE_ACCOUNT_KEY', value: 'mock')
        project.variables.build(protected: true, environment_scope: 'staging', key: 'GCP_PROJECT_ID', value: 'prj2')
        project.variables.build(protected: true, environment_scope: 'staging', key: 'GCP_SERVICE_ACCOUNT', value: 'mock')
        project.variables.build(protected: true, environment_scope: 'production', key: 'GCP_PROJECT_ID', value: 'prj3')
        project.variables.build(protected: true, environment_scope: 'production', key: 'GCP_SERVICE_ACCOUNT', value: 'mock')
        project.variables.build(protected: true, environment_scope: 'production', key: 'GCP_SERVICE_ACCOUNT_KEY', value: 'mock')
        project.save!
      end

      it 'returns a list of service accounts' do
        list = service.find_for_project

        aggregate_failures 'testing list of service accounts' do
          expect(list.length).to eq(3)

          expect(list.first[:ref]).to eq('*')
          expect(list.first[:gcp_project]).to eq('prj1')
          expect(list.first[:service_account_exists]).to eq(false)
          expect(list.first[:service_account_key_exists]).to eq(true)

          expect(list.second[:ref]).to eq('staging')
          expect(list.second[:gcp_project]).to eq('prj2')
          expect(list.second[:service_account_exists]).to eq(true)
          expect(list.second[:service_account_key_exists]).to eq(false)

          expect(list.third[:ref]).to eq('production')
          expect(list.third[:gcp_project]).to eq('prj3')
          expect(list.third[:service_account_exists]).to eq(true)
          expect(list.third[:service_account_key_exists]).to eq(true)
        end
      end
    end
  end

  describe 'add_for_project' do
    let_it_be(:project) { create(:project) }

    it 'saves GCP creds as project CI vars' do
      service.add_for_project('env_1', 'gcp_prj_id_1', 'srv_acc_1', 'srv_acc_key_1', true)
      service.add_for_project('env_2', 'gcp_prj_id_2', 'srv_acc_2', 'srv_acc_key_2', false)

      list = service.find_for_project

      aggregate_failures 'testing list of service accounts' do
        expect(list.length).to eq(2)

        expect(list.first[:ref]).to eq('env_1')
        expect(list.first[:gcp_project]).to eq('gcp_prj_id_1')
        expect(list.first[:service_account_exists]).to eq(true)
        expect(list.first[:service_account_key_exists]).to eq(true)

        expect(list.second[:ref]).to eq('env_2')
        expect(list.second[:gcp_project]).to eq('gcp_prj_id_2')
        expect(list.second[:service_account_exists]).to eq(true)
        expect(list.second[:service_account_key_exists]).to eq(true)
      end
    end

    it 'replaces previously stored CI vars with new CI vars' do
      service.add_for_project('env_1', 'new_project', 'srv_acc_1', 'srv_acc_key_1', false)

      list = service.find_for_project

      aggregate_failures 'testing list of service accounts' do
        expect(list.length).to eq(2)

        # asserting that the first service account is replaced
        expect(list.first[:ref]).to eq('env_1')
        expect(list.first[:gcp_project]).to eq('new_project')
        expect(list.first[:service_account_exists]).to eq(true)
        expect(list.first[:service_account_key_exists]).to eq(true)

        expect(list.second[:ref]).to eq('env_2')
        expect(list.second[:gcp_project]).to eq('gcp_prj_id_2')
        expect(list.second[:service_account_exists]).to eq(true)
        expect(list.second[:service_account_key_exists]).to eq(true)
      end
    end

    it 'underlying project CI vars must be protected as per value' do
      service.add_for_project('env_1', 'gcp_prj_id_1', 'srv_acc_1', 'srv_acc_key_1', true)
      service.add_for_project('env_2', 'gcp_prj_id_2', 'srv_acc_2', 'srv_acc_key_2', false)

      expect(project.variables[0].protected).to eq(true)
      expect(project.variables[1].protected).to eq(true)
      expect(project.variables[2].protected).to eq(true)
      expect(project.variables[3].protected).to eq(false)
      expect(project.variables[4].protected).to eq(false)
      expect(project.variables[5].protected).to eq(false)
    end
  end
end
