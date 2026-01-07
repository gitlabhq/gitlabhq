# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::JiraImport, :clean_gitlab_redis_shared_state, feature_category: :team_planning do
  let(:project_id) { 321 }

  describe '.validate_project_settings!' do
    include JiraIntegrationHelpers

    let_it_be(:project, reload: true) { create(:project) }

    let(:additional_params) { {} }

    subject { described_class.validate_project_settings!(project, **additional_params) }

    shared_examples 'raise Jira import error' do |message|
      it 'returns error' do
        expect { subject }.to raise_error(Projects::ImportService::Error, message)
      end
    end

    shared_examples 'jira configuration base checks' do
      context 'with configuration_check set to false' do
        before do
          additional_params[:configuration_check] = false
        end

        it 'does not raise Jira integration error' do
          expect { subject }.not_to raise_error
        end
      end

      context 'when Jira integration was not setup' do
        it_behaves_like 'raise Jira import error', 'Jira integration not configured.'
      end

      context 'when Jira integration exists' do
        let!(:jira_integration) { create(:jira_integration, project: project, active: true) }

        context 'when Jira connection is not valid' do
          before do
            WebMock.stub_request(:get, 'https://jira.example.com/rest/api/2/serverInfo')
              .to_raise(JIRA::HTTPError.new(double(message: 'Some failure.', code: '400')))
          end

          it_behaves_like 'raise Jira import error', 'Unable to connect to the Jira instance. Please check your Jira integration configuration.'
        end
      end
    end

    before do
      stub_jira_integration_test
    end

    context 'without user param' do
      it_behaves_like 'jira configuration base checks'

      context 'when jira connection is valid' do
        let!(:jira_integration) { create(:jira_integration, project: project, active: true) }

        it 'does not return any error' do
          expect { subject }.not_to raise_error
        end
      end
    end

    context 'with user param provided' do
      let_it_be(:user) { create(:user) }

      let(:additional_params) { { user: user } }

      context 'when user has permission to run import' do
        before do
          project.add_maintainer(user)
        end

        it_behaves_like 'jira configuration base checks'

        context 'when jira integration is configured' do
          let!(:jira_integration) { create(:jira_integration, project: project, active: true) }

          context 'when issues feature is disabled' do
            let_it_be(:project, reload: true) { create(:project, :issues_disabled) }

            it_behaves_like 'raise Jira import error', 'Cannot import because issues are not available in this project.'
          end

          context 'when everything is ok' do
            it 'does not return any error' do
              expect { subject }.not_to raise_error
            end
          end
        end
      end

      context 'when user does not have permissions to run the import' do
        before do
          create(:jira_integration, project: project, active: true)

          project.add_developer(user)
        end

        it_behaves_like 'raise Jira import error', 'You do not have permissions to run the import.'
      end
    end
  end

  describe '.already_imported_cache_key' do
    it 'returns cache key for already imported items' do
      expect(described_class.already_imported_cache_key(:issues, project_id)).to eq("jira-importer/already-imported/#{project_id}/issues")
    end
  end

  describe '.jira_issues_next_page_cache_key' do
    it 'returns cache key for next issues' do
      expect(described_class.jira_issues_next_page_cache_key(project_id)).to eq("jira-import/paginator/#{project_id}/issues")
    end
  end

  describe '.cache_users_mapping', :clean_gitlab_redis_cache do
    let(:data) { { 'user1' => '456', 'user234' => '23' } }

    it 'stores the data correctly' do
      described_class.cache_users_mapping(project_id, data)

      expect(Gitlab::Cache::Import::Caching.read("jira-import/items-mapper/#{project_id}/users/user1")).to eq('456')
      expect(Gitlab::Cache::Import::Caching.read("jira-import/items-mapper/#{project_id}/users/user234")).to eq('23')
    end
  end

  describe '.get_user_mapping', :clean_gitlab_redis_cache do
    it 'reads the data correctly' do
      Gitlab::Cache::Import::Caching.write("jira-import/items-mapper/#{project_id}/users/user-123", '456')

      expect(described_class.get_user_mapping(project_id, 'user-123')).to eq(456)
    end

    it 'returns nil if value not found' do
      expect(described_class.get_user_mapping(project_id, 'user-123')).to be_nil
    end
  end

  # New specs for pagination state methods
  describe '.get_pagination_state', :clean_gitlab_redis_cache do
    it 'returns default state when not defined' do
      state = described_class.get_pagination_state(project_id)

      expect(state).to eq({ is_last: false, next_page_token: nil, page: 1 })
    end

    it 'returns cached pagination state' do
      cached_state = { is_last: true, next_page_token: 'token123', page: 2 }
      described_class.store_pagination_state(project_id, cached_state)

      state = described_class.get_pagination_state(project_id)

      expect(state).to eq(cached_state)
    end
  end

  describe '.store_pagination_state', :clean_gitlab_redis_cache do
    it 'stores pagination state' do
      state = { is_last: false, next_page_token: 'token456', page: 3 }
      described_class.store_pagination_state(project_id, state)

      cached_state = described_class.get_pagination_state(project_id)
      expect(cached_state).to eq(state)
    end
  end
end
