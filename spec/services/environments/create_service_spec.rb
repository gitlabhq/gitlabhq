# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Environments::CreateService, feature_category: :environment_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }

  let(:service) { described_class.new(project, current_user, params) }
  let(:current_user) { developer }
  let(:params) { {} }

  describe '#execute' do
    subject { service.execute }

    let(:auto_stop_setting) { :always }
    let(:env_name) { 'production' }
    let(:tier) { nil }
    let(:params) { { name: env_name, description: 'description', tier: tier, external_url: 'https://gitlab.com', auto_stop_setting: auto_stop_setting } }

    it 'creates an environment' do
      expect { subject }.to change { ::Environment.count }.by(1)
    end

    it 'returns successful response' do
      response = subject

      expect(response).to be_success
      expect(response.payload[:environment].name).to eq('production')
      expect(response.payload[:environment].description).to eq('description')
      expect(response.payload[:environment].external_url).to eq('https://gitlab.com')
      expect(response.payload[:environment].tier).to eq('production')
      expect(response.payload[:environment].auto_stop_setting).to eq('always')
    end

    context 'when tier is provided' do
      let(:tier) { 'production' }
      let(:env_name) { 'testing' }

      it 'creates an environment' do
        expect { subject }.to change { ::Environment.count }.by(1)
      end

      it 'returns successful response' do
        response = subject

        expect(response).to be_success
        expect(response.payload[:environment].name).to eq('testing')
        expect(response.payload[:environment].tier).to eq('production')
        expect(response.payload[:environment].auto_stop_setting).to eq('always')
      end
    end

    context 'when tier is not provided' do
      context 'when environment name is production' do
        let(:env_name) { 'production' }

        it 'guesses tier to production' do
          response = subject

          expect(response).to be_success
          expect(response.payload[:environment].name).to eq('production')
          expect(response.payload[:environment].tier).to eq('production')
        end
      end

      context 'when environment name is testing' do
        let(:env_name) { 'testing' }

        it 'guesses tier to testing' do
          response = subject

          expect(response).to be_success
          expect(response.payload[:environment].name).to eq('testing')
          expect(response.payload[:environment].tier).to eq('testing')
        end
      end
    end

    context 'when auto_stop_setting is not provided' do
      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(new_default_for_auto_stop: false)
        end

        let(:tier) { 'production' }
        let(:env_name) { 'production' }
        let(:auto_stop_setting) { nil }

        it 'creates an environment' do
          expect { subject }.to change { ::Environment.count }.by(1)
        end

        it 'sets :always for auto_stop_setting' do
          expect_next_instance_of(Environment) do |instance|
            expect(instance).to receive(:set_default_auto_stop_setting).and_call_original
          end

          response = subject
          expect(response).to be_success
          expect(response.payload[:environment].name).to eq(env_name)
          expect(response.payload[:environment].auto_stop_setting).to eq('always')
        end
      end

      context 'when environment tier is production' do
        let(:tier) { 'production' }
        let(:env_name) { 'production' }
        let(:auto_stop_setting) { nil }

        it 'creates an environment' do
          expect { subject }.to change { ::Environment.count }.by(1)
        end

        it 'sets :with_action for auto_stop_setting' do
          expect_next_instance_of(Environment) do |instance|
            expect(instance).to receive(:set_default_auto_stop_setting).and_call_original
          end

          response = subject
          expect(response).to be_success
          expect(response.payload[:environment].name).to eq(env_name)
          expect(response.payload[:environment].auto_stop_setting).to eq('with_action')
        end
      end

      context 'when environment tier is development' do
        let(:tier) { 'development' }
        let(:env_name) { 'development' }
        let(:auto_stop_setting) { nil }

        it 'creates an environment' do
          expect { subject }.to change { ::Environment.count }.by(1)
        end

        it 'sets :always for auto_stop_setting' do
          expect_next_instance_of(Environment) do |instance|
            expect(instance).to receive(:set_default_auto_stop_setting).and_call_original
          end

          response = subject
          expect(response).to be_success
          expect(response.payload[:environment].name).to eq(env_name)
          expect(response.payload[:environment].auto_stop_setting).to eq('always')
        end
      end
    end

    context 'with a cluster agent' do
      let_it_be(:agent_management_project) { create(:project) }
      let_it_be(:cluster_agent) { create(:cluster_agent, project: agent_management_project) }

      let!(:authorization) { create(:agent_user_access_project_authorization, project: project, agent: cluster_agent) }
      let(:params) do
        {
          name: 'production',
          cluster_agent: cluster_agent,
          kubernetes_namespace: 'default',
          flux_resource_path: 'path/to/flux/resource'
        }
      end

      it 'returns successful response' do
        response = subject

        expect(response).to be_success
        expect(response.payload[:environment].cluster_agent).to eq(cluster_agent)
        expect(response.payload[:environment].kubernetes_namespace).to eq('default')
        expect(response.payload[:environment].flux_resource_path).to eq('path/to/flux/resource')
      end

      context 'when user does not have permission to read the agent' do
        let!(:authorization) { nil }

        it 'returns an error' do
          response = subject

          expect(response).to be_error
          expect(response.message).to eq('Unauthorized to access the cluster agent in this project')
          expect(response.payload[:environment]).to be_nil
        end
      end
    end

    context 'when params contain invalid values' do
      let(:params) { { name: 'production', external_url: 'http://${URL}', kubernetes_namespace: "invalid" } }

      it 'does not create an environment' do
        expect { subject }.not_to change { ::Environment.count }
      end

      it 'returns an error' do
        response = subject

        expect(response).to be_error
        expect(response.message).to match_array(["External url URI is invalid",
          "Kubernetes namespace cannot be set without a cluster agent"])
        expect(response.payload[:environment]).to be_nil
      end
    end

    context 'when params contain invalid auto_stop_setting' do
      let(:params) { { name: 'production', auto_stop_setting: :invalid } }

      it 'does not create an environment' do
        expect { subject }.not_to change { ::Environment.count }
      end

      it 'returns an error' do
        response = subject

        expect(response).to be_error
        expect(response.message).to match_array("'invalid' is not a valid auto_stop_setting")
        expect(response.payload[:environment]).to be_nil
      end
    end

    context 'when disallowed parameter is passed' do
      let(:params) { { name: 'production', slug: 'prod' } }

      it 'ignores the parameter' do
        response = subject

        expect(response).to be_success
        expect(response.payload[:environment].name).to eq('production')
        expect(response.payload[:environment].slug).not_to eq('prod')
      end
    end

    context 'when user is reporter' do
      let(:current_user) { reporter }

      it 'does not create an environment' do
        expect { subject }.not_to change { ::Environment.count }
      end

      it 'returns an error' do
        response = subject

        expect(response).to be_error
        expect(response.message).to eq('Unauthorized to create an environment')
        expect(response.payload[:environment]).to be_nil
      end
    end
  end
end
