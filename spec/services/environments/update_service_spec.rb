# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Environments::UpdateService, feature_category: :environment_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }
  let_it_be_with_reload(:environment) { create(:environment, project: project) }

  let(:service) { described_class.new(project, current_user, params) }
  let(:current_user) { developer }
  let(:params) { {} }

  describe '#execute' do
    subject { service.execute(environment) }

    let(:params) { { external_url: 'https://gitlab.com/', description: 'description', auto_stop_setting: :with_action } }

    it 'updates the external URL' do
      expect { subject }.to change { environment.reload.external_url }.to('https://gitlab.com/')
    end

    it 'updates the description' do
      expect { subject }.to change { environment.reload.description }.to('description')
    end

    it 'updates the auto stop setting' do
      expect { subject }.to change { environment.reload.auto_stop_setting }.to('with_action')
    end

    it 'returns successful response' do
      response = subject

      expect(response).to be_success
      expect(response.payload[:environment]).to eq(environment)
    end

    context 'when setting cluster agent configuration fields for the environment' do
      let_it_be(:agent_management_project) { create(:project) }
      let_it_be(:cluster_agent) { create(:cluster_agent, project: agent_management_project) }

      let!(:authorization) { create(:agent_user_access_project_authorization, project: project, agent: cluster_agent) }
      let(:params) do
        {
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
          expect(response.payload[:environment]).to eq(environment)
        end
      end
    end

    context 'when unsetting a cluster agent of the environment' do
      let_it_be(:cluster_agent) { create(:cluster_agent, project: project) }

      let(:params) { { cluster_agent: nil } }

      before do
        environment.update!(cluster_agent: cluster_agent)
      end

      it 'returns successful response' do
        response = subject

        expect(response).to be_success
        expect(response.payload[:environment].cluster_agent).to be_nil
      end
    end

    context 'when params contain invalid values' do
      let(:params) { { external_url: 'http://${URL}', kubernetes_namespace: "invalid" } }

      it 'returns an error' do
        response = subject

        expect(response).to be_error
        expect(response.message).to match_array(["External url URI is invalid",
          "Kubernetes namespace cannot be set without a cluster agent"])
        expect(response.payload[:environment]).to eq(environment)
      end
    end

    context 'when params contain invalid auto_stop_setting' do
      let(:params) { { auto_stop_setting: :invalid } }

      it 'returns an error' do
        response = subject

        expect(response).to be_error
        expect(response.message).to match_array("'invalid' is not a valid auto_stop_setting")
        expect(response.payload[:environment]).to eq(environment)
      end
    end

    context 'when disallowed parameter is passed' do
      let(:params) { { external_url: 'https://gitlab.com/', slug: 'prod' } }

      it 'ignores the parameter' do
        response = subject

        expect(response).to be_success
        expect(response.payload[:environment].external_url).to eq('https://gitlab.com/')
        expect(response.payload[:environment].slug).not_to eq('prod')
      end
    end

    context 'when user is reporter' do
      let(:current_user) { reporter }

      it 'returns an error' do
        response = subject

        expect(response).to be_error
        expect(response.message).to eq('Unauthorized to update the environment')
        expect(response.payload[:environment]).to eq(environment)
      end
    end
  end
end
