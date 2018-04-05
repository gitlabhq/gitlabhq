require 'spec_helper'

describe Projects::Settings::DeployTokensPresenter do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let!(:project_deploy_tokens) { create_list(:project_deploy_token, 3, project: project) }
  let(:deploy_tokens) { project.deploy_tokens }

  subject(:presenter) { described_class.new(deploy_tokens, current_user: user, project: project) }

  describe '#length' do
    it 'returns the size of deploy tokens presented' do
      expect(presenter.length).to eq(3)
    end
  end

  describe '#temporal_token' do
    context 'when a deploy token has been created recently' do
      it 'returns the token of the deploy' do
        deploy_token = ::DeployTokens::CreateService.new(project, user, attributes_for(:deploy_token)).execute

        expect(presenter.temporal_token).to eq(deploy_token.token)
      end
    end

    context 'when a deploy token has not been created recently' do
      it 'does returns nil' do
        expect(presenter.temporal_token).to be_nil
      end
    end
  end
end
