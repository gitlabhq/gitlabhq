require 'spec_helper'

describe Projects::Settings::DeployKeysPresenter do
  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }

  subject(:presenter) do
    described_class.new(project, current_user: user)
  end

  it 'inherits from Gitlab::View::Presenter::Simple' do
    expect(described_class.superclass).to eq(Gitlab::View::Presenter::Simple)
  end

  describe '#enabled_keys' do
    let(:deploy_key) do
      create(:deploy_keys_project, project: project).deploy_key
    end

    it 'returns project keys' do
      expect(presenter.enabled_keys).to eq [deploy_key]
    end

    it 'does not contain enabled_keys inside available_keys' do
      expect(presenter.available_keys).not_to include deploy_key
    end
  end
end
