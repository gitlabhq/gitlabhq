# frozen_string_literal: true

require 'spec_helper'

describe Projects::Settings::DeployKeysPresenter do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  subject(:presenter) do
    described_class.new(project, current_user: user)
  end

  it 'inherits from Gitlab::View::Presenter::Simple' do
    expect(described_class.superclass).to eq(Gitlab::View::Presenter::Simple)
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

    def execute_with_query_count
      ActiveRecord::QueryRecorder.new { execute_presenter }.count
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

      count_before = execute_with_query_count

      3.times { create_records }

      count_after = execute_with_query_count

      expect(count_after).to eq(count_before)

      result = execute_presenter
      expect(result[:enabled_keys].size).to eq(4)
      expect(result[:available_project_keys].size).to eq(4)
      expect(result[:public_keys].size).to eq(4)
    end
  end
end
