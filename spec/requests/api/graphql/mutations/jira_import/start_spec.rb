# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Starting a Jira Import', feature_category: :importers do
  include JiraIntegrationHelpers
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project) }

  let(:jira_project_key) { 'AA' }
  let(:project_path) { project.full_path }

  let(:mutation) do
    variables = {
      jira_project_key: jira_project_key,
      project_path: project_path,
      users_mapping: [{ jiraAccountId: 'abc', gitlabId: 5 }]
    }

    graphql_mutation(:jira_import_start, variables)
  end

  def mutation_response
    graphql_mutation_response(:jira_import_start)
  end

  def jira_import
    mutation_response['jiraImport']
  end

  context 'when the user does not have permission' do
    shared_examples 'Jira import does not start' do
      it 'does not start the Jira import' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(project.reload.import_state).to be_nil
        expect(project.reload.import_data).to be_nil
      end
    end

    context 'with anonymous user' do
      let(:current_user) { nil }

      it_behaves_like 'Jira import does not start'
      it_behaves_like 'a mutation that returns top-level errors',
        errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
    end

    context 'with user without permissions' do
      let(:current_user) { user }
      let(:project_path) { project.full_path }

      before do
        project.add_developer(current_user)
      end

      it_behaves_like 'Jira import does not start'
      it_behaves_like 'a mutation that returns top-level errors',
        errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
    end
  end

  context 'when the user has permission' do
    let(:current_user) { user }

    before do
      project.add_maintainer(current_user)
    end

    context 'with project' do
      context 'when the project path is invalid' do
        let(:project_path) { 'foobar' }

        it 'returns an an error' do
          post_graphql_mutation(mutation, current_user: current_user)
          errors = json_response['errors']

          expect(errors.first['message']).to eq(Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR)
        end
      end

      context 'when project has no Jira integration' do
        it_behaves_like 'a mutation that returns errors in the response', errors: ['Jira integration not configured.']
      end

      context 'when when project has Jira integration' do
        let!(:service) { create(:jira_integration, project: project) }

        before do
          project.reload

          stub_jira_integration_test
        end

        context 'when issues feature are disabled' do
          let_it_be(:project, reload: true) { create(:project, :issues_disabled) }

          it_behaves_like 'a mutation that returns errors in the response', errors: ['Cannot import because issues are not available in this project.']
        end

        context 'when jira_project_key not provided' do
          let(:jira_project_key) { '' }

          it_behaves_like 'a mutation that returns errors in the response', errors: ['Unable to find Jira project to import data from.']
        end

        context 'when Jira import successfully scheduled' do
          it 'schedules a Jira import' do
            post_graphql_mutation(mutation, current_user: current_user)

            expect(jira_import['jiraProjectKey']).to eq 'AA'
            expect(jira_import['scheduledBy']['username']).to eq current_user.username
            expect(project.latest_jira_import).not_to be_nil
            expect(project.latest_jira_import).to be_scheduled
          end
        end
      end
    end
  end
end
