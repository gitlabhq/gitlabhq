# frozen_string_literal: true

require 'spec_helper'

describe 'query jira import data' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:jira_import_data) do
    data = JiraImportData.new
    data << JiraImportData::JiraProjectDetails.new(
      'AA', 2.days.ago.strftime('%Y-%m-%d %H:%M:%S'),
      { user_id: current_user.id, name: current_user.name }
    )
    data << JiraImportData::JiraProjectDetails.new(
      'BB', 5.days.ago.strftime('%Y-%m-%d %H:%M:%S'),
      { user_id: current_user.id, name: current_user.name }
    )
    data
  end
  let_it_be(:project) { create(:project, :private, :import_started, import_data: jira_import_data, import_type: 'jira') }
  let(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          jiraImportStatus
          jiraImports {
            nodes {
              jiraProjectKey
              scheduledAt
              scheduledBy {
                username
              }
            }
          }
        }
      }
    )
  end
  let(:jira_imports) { graphql_data.dig('project', 'jiraImports', 'nodes')}
  let(:jira_import_status) { graphql_data.dig('project', 'jiraImportStatus')}

  context 'when user cannot read Jira import data' do
    before do
      post_graphql(query, current_user: current_user)
    end

    context 'when anonymous user' do
      let(:current_user) { nil }

      it { expect(jira_imports).to be nil }
    end

    context 'when user developer' do
      before do
        project.add_developer(current_user)
      end

      it { expect(jira_imports).to be nil }
    end
  end

  context 'when user can access Jira import data' do
    before do
      project.add_maintainer(current_user)
      post_graphql(query, current_user: current_user)
    end

    it_behaves_like 'a working graphql query'

    context 'list of jira imports sorted ascending by scheduledAt time' do
      it 'retuns list of jira imports' do
        jira_proket_keys = jira_imports.map {|ji| ji['jiraProjectKey']}
        usernames = jira_imports.map {|ji| ji.dig('scheduledBy', 'username')}

        expect(jira_imports.size).to eq 2
        expect(jira_proket_keys).to eq %w(BB AA)
        expect(usernames).to eq [current_user.username, current_user.username]
      end
    end

    describe 'jira imports pagination' do
      context 'first jira import' do
        let(:query) do
          %(
            query {
              project(fullPath:"#{project.full_path}") {
                jiraImports(first: 1) {
                  nodes {
                    jiraProjectKey
                    scheduledBy {
                      username
                    }
                  }
                }
              }
            }
          )
        end

        it 'returns latest jira import data' do
          first_jira_import = jira_imports.first

          expect(first_jira_import['jiraProjectKey']).to eq 'BB'
          expect(first_jira_import.dig('scheduledBy', 'username')).to eq current_user.username
        end
      end

      context 'lastest jira import' do
        let(:query) do
          %(
            query {
              project(fullPath:"#{project.full_path}") {
                jiraImports(last: 1) {
                  nodes {
                    jiraProjectKey
                    scheduledBy {
                      username
                    }
                  }
                }
              }
            }
          )
        end

        it 'returns latest jira import data' do
          latest_jira_import = jira_imports.first

          expect(latest_jira_import['jiraProjectKey']).to eq 'AA'
          expect(latest_jira_import.dig('scheduledBy', 'username')).to eq current_user.username
        end
      end
    end
  end

  context 'jira import status' do
    context 'when user cannot access project' do
      it 'does not return import status' do
        post_graphql(query, current_user: current_user)

        expect(graphql_data['project']).to be nil
      end
    end

    context 'when user can access project' do
      before do
        project.add_guest(current_user)
      end

      context 'when import never ran' do
        let(:project) { create(:project) }

        it 'returns import status' do
          post_graphql(query, current_user: current_user)

          expect(jira_import_status).to eq('none')
        end
      end

      context 'when import finished' do
        it 'returns import status' do
          post_graphql(query, current_user: current_user)

          expect(jira_import_status).to eq('finished')
        end
      end

      context 'when import running, i.e. force-import: true' do
        before do
          project.import_data.becomes(JiraImportData).force_import!
          project.save!
        end

        it 'returns import status' do
          post_graphql(query, current_user: current_user)

          expect(jira_import_status).to eq('started')
        end
      end
    end
  end
end
