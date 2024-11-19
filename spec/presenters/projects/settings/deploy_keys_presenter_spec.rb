# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Settings::DeployKeysPresenter do
  let_it_be(:project, refind: true) { create(:project) }
  let_it_be(:other_project) { create(:project) }
  let_it_be(:user) { create(:user, maintainer_of: [project, other_project]) }

  subject(:presenter) do
    described_class.new(project, current_user: user)
  end

  it 'inherits from Gitlab::View::Presenter::Simple' do
    expect(described_class.superclass).to eq(Gitlab::View::Presenter::Simple)
  end

  describe 'deploy key groups' do
    let_it_be(:deploy_key) { create(:deploy_key, projects: [project]) }
    let_it_be(:other_deploy_key) { create(:deploy_key, projects: [other_project]) }
    let_it_be(:public_deploy_key) { create(:deploy_key, public: true) }
    let_it_be(:unrelated_project) { create(:project, :private) }
    let_it_be(:unrelated_deploy_key) { create(:deploy_key, projects: [unrelated_project]) }

    context 'with enabled keys' do
      it 'returns correct deploy keys' do
        expect(presenter.enabled_keys).to eq([deploy_key])
        expect(presenter.enabled_keys_size).to eq(1)
      end
    end

    context 'with available keys' do
      it 'returns correct deploy keys' do
        expect(presenter.available_keys).to eq([other_deploy_key, public_deploy_key])
      end
    end

    context 'with available project keys' do
      it 'returns correct deploy keys' do
        expect(presenter.available_project_keys).to eq([other_deploy_key])
        expect(presenter.available_project_keys_size).to eq(1)
      end
    end

    context 'with available public keys' do
      it 'returns correct deploy keys' do
        expect(presenter.available_public_keys).to eq([public_deploy_key])
        expect(presenter.available_public_keys_size).to eq(1)
      end
    end
  end

  describe '#enabled_keys' do
    let!(:deploy_key) { create(:deploy_key, public: true) }

    let!(:deploy_keys_project) do
      create(:deploy_keys_project, project: project, deploy_key: deploy_key)
    end

    it 'returns currently enabled keys' do
      expect(presenter.enabled_keys).to eq [deploy_keys_project.deploy_key]
    end

    it 'does not contain enabled_keys inside available_keys' do
      expect(presenter.available_keys).not_to include deploy_key
    end

    it 'returns the enabled_keys size' do
      expect(presenter.enabled_keys_size).to eq(1)
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
  end

  context 'prevent N + 1 queries' do
    before do
      allow(Ability).to receive(:allowed?).and_return(true)

      create_records

      project.add_maintainer(user)
    end

    def create_records
      other_project = create(:project)
      other_project.add_maintainer(user)

      create(:deploy_keys_project, project: project, deploy_key: create(:deploy_key))
      create(:deploy_keys_project, project: other_project, deploy_key: create(:deploy_key))
      create(:deploy_key, public: true)
    end

    def execute_with_query_recorder
      ActiveRecord::QueryRecorder.new { execute_presenter }
    end

    def execute_presenter
      described_class.new(project, current_user: user).as_json
    end

    it 'returns correct counts' do
      result = execute_presenter

      expect(result[:enabled_keys].size).to eq(1)
      expect(result[:available_project_keys].size).to eq(1)
      expect(result[:public_keys].size).to eq(1)
    end

    it 'does not increase the query count' do
      execute_presenter # make sure everything is cached

      control = execute_with_query_recorder

      3.times { create_records }

      expect { execute_presenter }.to issue_same_number_of_queries_as(control)

      result = execute_presenter
      expect(result[:enabled_keys].size).to eq(4)
      expect(result[:available_project_keys].size).to eq(4)
      expect(result[:public_keys].size).to eq(4)
    end
  end
end
