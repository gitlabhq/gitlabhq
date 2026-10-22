# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Settings::DeployKeysPresenter, feature_category: :continuous_delivery do
  let_it_be_with_refind(:project) { create(:project) }
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

    context 'with keys from other organizations' do
      let_it_be(:isolated_organization) { create(:organization, :isolated) }
      let_it_be(:isolated_user) { create(:user, organizations: [isolated_organization]) }
      let_it_be(:isolated_project) do
        create(:project, organization: isolated_organization, maintainers: isolated_user)
      end

      let_it_be(:other_isolated_project) do
        create(:project, organization: isolated_organization, maintainers: isolated_user)
      end

      let_it_be(:other_organization_project_key) do
        create(:deploy_key, organization: create(:organization), projects: [other_project, other_isolated_project])
      end

      let_it_be(:isolated_organization_project_key) do
        create(:deploy_key, organization: isolated_organization, projects: [other_project, other_isolated_project])
      end

      let_it_be(:other_organization_public_key) do
        create(:deploy_key, public: true, organization: create(:organization))
      end

      let_it_be(:isolated_organization_public_key) do
        create(:deploy_key, public: true, organization: isolated_organization)
      end

      it 'excludes keys from isolated organizations', :aggregate_failures do
        expect(presenter.available_project_keys).to contain_exactly(other_deploy_key, other_organization_project_key)
        expect(presenter.available_project_keys_size).to eq(2)
        expect(presenter.available_public_keys).to contain_exactly(public_deploy_key, other_organization_public_key)
        expect(presenter.available_public_keys_size).to eq(2)
      end

      context 'when the project organization is isolated' do
        subject(:presenter) { described_class.new(isolated_project, current_user: isolated_user) }

        it 'returns only keys from the project organization', :aggregate_failures do
          expect(presenter.available_project_keys).to contain_exactly(isolated_organization_project_key)
          expect(presenter.available_project_keys_size).to eq(1)
          expect(presenter.available_public_keys).to contain_exactly(isolated_organization_public_key)
          expect(presenter.available_public_keys_size).to eq(1)
        end
      end
    end
  end

  describe '#enabled_keys' do
    let_it_be(:deploy_key) { create(:deploy_key, public: true, projects: [project]) }

    it 'returns currently enabled keys' do
      expect(presenter.enabled_keys).to eq [deploy_key]
    end

    it 'does not contain enabled_keys inside available_keys' do
      expect(presenter.available_keys).not_to include deploy_key
    end

    it 'returns the enabled_keys size' do
      expect(presenter.enabled_keys_size).to eq(1)
    end
  end

  describe '#available_keys/#available_project_keys' do
    let_it_be(:other_deploy_key) { create(:another_deploy_key, projects: [other_project]) }

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
    before_all do
      create_records
    end

    before do
      allow(Ability).to receive(:allowed?).and_return(true)
    end

    def create_records
      other_project = create(:project, maintainers: user)

      create(:deploy_key, projects: [project])
      create(:deploy_key, projects: [other_project])
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

      expect { execute_presenter }.to issue_same_number_of_queries_as(control).allow_skip_cache_inconsistency

      result = execute_presenter
      expect(result[:enabled_keys].size).to eq(4)
      expect(result[:available_project_keys].size).to eq(4)
      expect(result[:public_keys].size).to eq(4)
    end
  end
end
