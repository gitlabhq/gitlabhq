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
end
