# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Importing Jira Users', feature_category: :importers do
  include JiraIntegrationHelpers
  include GraphqlHelpers

  let_it_be(:user)    { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:importer) { instance_double(JiraImport::UsersImporter) }
  let(:project_path)  { project.full_path }
  let(:start_at)      { 7 }
  let(:variables) do
    {
      start_at: start_at,
      project_path: project_path
    }
  end

  let(:mutation) do
    graphql_mutation(:jira_import_users, variables)
  end

  def mutation_response
    graphql_mutation_response(:jira_import_users)
  end

  def jira_import
    mutation_response['jiraUsers']
  end

  context 'with anonymous user' do
    let(:current_user) { nil }

    it_behaves_like 'a mutation that returns top-level errors',
      errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
  end

  context 'with user without permissions' do
    let(:current_user) { user }

    before do
      project.add_developer(current_user)
    end

    it_behaves_like 'a mutation that returns top-level errors',
      errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
  end

  context 'when the user has permissions' do
    let(:current_user) { user }

    before do
      project.add_maintainer(current_user)
    end

    context 'when the project path is invalid' do
      let(:project_path) { 'foobar' }

      it 'returns an an error' do
        post_graphql_mutation(mutation, current_user: current_user)

        errors = json_response['errors']

        expect(errors.first['message']).to eq(Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR)
      end
    end

    context 'with start_at' do
      RSpec.shared_examples 'start users import at zero' do
        it 'returns imported users' do
          users = [{ jira_account_id: '12a', jira_display_name: 'user 1' }]
          result = ServiceResponse.success(payload: users)

          expect(importer).to receive(:execute).and_return(result)
          expect(JiraImport::UsersImporter).to receive(:new).with(current_user, project, 0).and_return(importer)

          post_graphql_mutation(mutation, current_user: current_user)
        end
      end

      context 'when nil' do
        let(:variables) do
          {
            start_at: nil,
            project_path: project_path
          }
        end

        it_behaves_like 'start users import at zero'
      end

      context 'when not provided' do
        let(:variables) { { project_path: project_path } }

        it_behaves_like 'start users import at zero'
      end
    end

    context 'when all params and permissions are ok' do
      before do
        expect(JiraImport::UsersImporter).to receive(:new).with(current_user, project, 7)
          .and_return(importer)
      end

      context 'when service returns a successful response' do
        it 'returns imported users' do
          users = [{ jira_account_id: '12a', jira_display_name: 'user 1' }]
          result = ServiceResponse.success(payload: users)

          expect(importer).to receive(:execute).and_return(result)

          post_graphql_mutation(mutation, current_user: current_user)

          expect(jira_import.length).to eq(1)
          expect(jira_import.first['jiraAccountId']).to eq('12a')
          expect(jira_import.first['jiraDisplayName']).to eq('user 1')
        end
      end

      context 'when service returns an error response' do
        it 'returns an error messaege' do
          result = ServiceResponse.error(message: 'Some error')

          expect(importer).to receive(:execute).and_return(result)

          post_graphql_mutation(mutation, current_user: current_user)

          expect(mutation_response['errors']).to eq(['Some error'])
        end
      end
    end
  end
end
