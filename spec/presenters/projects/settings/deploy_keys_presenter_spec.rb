require 'spec_helper'

describe Projects::Settings::DeployKeysPresenter do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:deploy_key)  { create(:deploy_key, public: true) }

  let!(:deploy_keys_project) do
    create(:deploy_keys_project, project: project, deploy_key: deploy_key)
  end

  subject(:presenter) do
    described_class.new(project, current_user: user)
  end

  it 'inherits from Gitlab::View::Presenter::Simple' do
    expect(described_class.superclass).to eq(Gitlab::View::Presenter::Simple)
  end

  describe '#enabled_keys' do
    it 'returns currently enabled keys' do
      expect(presenter.enabled_keys).to eq [deploy_keys_project.deploy_key]
    end

    it 'does not contain enabled_keys inside available_keys' do
      expect(presenter.available_keys).not_to include deploy_key
    end

    it 'returns the enabled_keys size' do
      expect(presenter.enabled_keys_size).to eq(1)
    end

    it 'returns true if there is any enabled_keys' do
      expect(presenter.any_keys_enabled?).to eq(true)
    end
  end

  describe '#available_keys/#available_project_keys' do
    let(:other_deploy_key) { create(:another_deploy_key) }

    before do
      project_key = create(:deploy_keys_project, deploy_key: other_deploy_key)
      project_key.project.add_developer(user)
    end

    it 'returns the current available_keys' do
      expect(presenter.available_keys).not_to be_empty
    end

    it 'returns the current available_project_keys' do
      expect(presenter.available_project_keys).not_to be_empty
    end

    it 'returns the available_project_keys size' do
      expect(presenter.available_project_keys_size).to eq(1)
    end

    it 'shows if there is an available key' do
      expect(presenter.key_available?(deploy_key)).to eq(false)
    end
  end
end
