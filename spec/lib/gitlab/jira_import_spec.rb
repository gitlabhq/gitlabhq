# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::JiraImport do
  let(:project_id) { 321 }

  describe '.validate_project_settings!' do
    include JiraServiceHelper

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
              .to_raise(JIRA::HTTPError.new(double(message: 'Some failure.')))
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

  describe '.jira_issue_cache_key' do
    it 'returns cache key for Jira issue imported to given project' do
      expect(described_class.jira_item_cache_key(project_id, 'DEMO-123', :issues)).to eq("jira-import/items-mapper/#{project_id}/issues/DEMO-123")
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

  describe '.get_issues_next_start_at', :clean_gitlab_redis_cache do
    it 'returns zero when not defined' do
      expect(Gitlab::Cache::Import::Caching.read("jira-import/paginator/#{project_id}/issues")).to be nil
      expect(described_class.get_issues_next_start_at(project_id)).to eq(0)
    end

    it 'returns negative value for next issues to be imported starting point' do
      Gitlab::Cache::Import::Caching.write("jira-import/paginator/#{project_id}/issues", -10)

      expect(Gitlab::Cache::Import::Caching.read("jira-import/paginator/#{project_id}/issues")).to eq('-10')
      expect(described_class.get_issues_next_start_at(project_id)).to eq(-10)
    end

    it 'returns cached value for next issues to be imported starting point' do
      Gitlab::Cache::Import::Caching.write("jira-import/paginator/#{project_id}/issues", 10)

      expect(Gitlab::Cache::Import::Caching.read("jira-import/paginator/#{project_id}/issues")).to eq('10')
      expect(described_class.get_issues_next_start_at(project_id)).to eq(10)
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

  describe '.store_issues_next_started_at', :clean_gitlab_redis_cache do
    it 'stores nil value' do
      described_class.store_issues_next_started_at(project_id, nil)

      expect(Gitlab::Cache::Import::Caching.read("jira-import/paginator/#{project_id}/issues")).to eq ''
      expect(Gitlab::Cache::Import::Caching.read("jira-import/paginator/#{project_id}/issues").to_i).to eq(0)
    end

    it 'stores positive value' do
      described_class.store_issues_next_started_at(project_id, 10)

      expect(Gitlab::Cache::Import::Caching.read("jira-import/paginator/#{project_id}/issues").to_i).to eq(10)
    end

    it 'stores negative value' do
      described_class.store_issues_next_started_at(project_id, -10)

      expect(Gitlab::Cache::Import::Caching.read("jira-import/paginator/#{project_id}/issues").to_i).to eq(-10)
    end
  end
end
