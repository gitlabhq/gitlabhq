require 'spec_helper'

describe Projects::Settings::DeployTokensPresenter do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:deploy_tokens) { create_list(:deploy_token, 3, project: project) }

  subject(:presenter) { described_class.new(deploy_tokens, current_user: user, project: project) }

  describe '#available_scopes' do
    it 'returns the all the deploy token scopes' do
      expect(presenter.available_scopes).to match_array(%w(read_repo read_registry))
    end
  end

  describe '#scope_description' do
    let(:deploy_token) { create(:deploy_token, project: project, scopes: [:read_registry]) }

    it 'returns the description for a given scope' do
      description = 'Allows read-only access to the registry images'
      expect(presenter.scope_description('read_registry')).to eq(description)
    end
  end

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
