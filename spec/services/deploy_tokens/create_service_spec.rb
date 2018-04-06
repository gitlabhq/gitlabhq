require 'spec_helper'

describe DeployTokens::CreateService, :clean_gitlab_redis_shared_state do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:deploy_token_params) { attributes_for(:deploy_token) }

  describe '#execute' do
    subject { described_class.new(project, user, deploy_token_params).execute }

    context 'when the deploy token is valid' do
      it 'should create a new DeployToken' do
        expect { subject }.to change { DeployToken.count }.by(1)
      end

      it 'should create a new ProjectDeployToken' do
        expect { subject }.to change { ProjectDeployToken.count }.by(1)
      end

      it 'returns a DeployToken' do
        expect(subject).to be_an_instance_of DeployToken
      end
    end

    context 'when the deploy token is invalid' do
      let(:deploy_token_params) { attributes_for(:deploy_token, read_repository: false, read_registry: false) }

      it 'should not create a new DeployToken' do
        expect { subject }.not_to change { DeployToken.count }
      end

      it 'should not create a new ProjectDeployToken' do
        expect { subject }.not_to change { ProjectDeployToken.count }
      end
    end
  end
end
