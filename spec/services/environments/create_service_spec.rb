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

    let(:params) { { name: 'production', external_url: 'https://gitlab.com', tier: :production, kubernetes_namespace: 'default', flux_resource_path: 'path/to/flux/resource' } }

    it 'creates an environment' do
      expect { subject }.to change { ::Environment.count }.by(1)
    end

    it 'returns successful response' do
      response = subject

      expect(response).to be_success
      expect(response.payload[:environment].name).to eq('production')
      expect(response.payload[:environment].external_url).to eq('https://gitlab.com')
      expect(response.payload[:environment].tier).to eq('production')
      expect(response.payload[:environment].kubernetes_namespace).to eq('default')
      expect(response.payload[:environment].flux_resource_path).to eq('path/to/flux/resource')
    end

    context 'with a cluster agent' do
      let_it_be(:agent_management_project) { create(:project) }
      let_it_be(:cluster_agent) { create(:cluster_agent, project: agent_management_project) }

      let!(:authorization) { create(:agent_user_access_project_authorization, project: project, agent: cluster_agent) }
      let(:params) { { name: 'production', cluster_agent: cluster_agent } }

      it 'returns successful response' do
        response = subject

        expect(response).to be_success
        expect(response.payload[:environment].cluster_agent).to eq(cluster_agent)
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

    context 'when params contain invalid value' do
      let(:params) { { name: 'production', external_url: 'http://${URL}' } }

      it 'does not create an environment' do
        expect { subject }.not_to change { ::Environment.count }
      end

      it 'returns an error' do
        response = subject

        expect(response).to be_error
        expect(response.message).to match_array("External url URI is invalid")
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
