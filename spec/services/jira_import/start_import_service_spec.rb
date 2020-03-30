# frozen_string_literal: true

require 'spec_helper'

describe JiraImport::StartImportService do
  let_it_be(:user) { create(:user) }
  let(:project) { create(:project) }

  subject { described_class.new(user, project, '').execute }

  context 'when feature flag disabled' do
    before do
      stub_feature_flags(jira_issue_import: false)
    end

    it_behaves_like 'responds with error', 'Jira import feature is disabled.'
  end

  context 'when feature flag enabled' do
    before do
      stub_feature_flags(jira_issue_import: true)
    end

    context 'when user does not have permissions to run the import' do
      before do
        project.add_developer(user)
      end

      it_behaves_like 'responds with error', 'You do not have permissions to run the import.'
    end

    context 'when user has permission to run import' do
      before do
        project.add_maintainer(user)
      end

      context 'when Jira service was not setup' do
        it_behaves_like 'responds with error', 'Jira integration not configured.'
      end

      context 'when Jira service exists' do
        let!(:jira_service) { create(:jira_service, project: project, active: true) }

        context 'when Jira project key is not provided' do
          it_behaves_like 'responds with error', 'Unable to find Jira project to import data from.'
        end

        context 'when correct data provided' do
          subject { described_class.new(user, project, 'some-key').execute }

          context 'when import is already running' do
            let!(:import_state) { create(:import_state, project: project, status: :started) }

            it_behaves_like 'responds with error', 'Jira import is already running.'
          end

          it 'returns success response' do
            expect(subject).to be_a(ServiceResponse)
            expect(subject).to be_success
          end

          it 'schedules jira import' do
            subject

            expect(project.import_state.status).to eq('scheduled')
          end

          it 'creates jira import data' do
            subject

            jira_import_data = project.import_data.becomes(JiraImportData)
            expect(jira_import_data.force_import?).to be true
            imported_project_data = jira_import_data.projects.last
            expect(imported_project_data.key).to eq('some-key')
            expect(imported_project_data.scheduled_by['user_id']).to eq(user.id)
          end
        end
      end
    end
  end
end
