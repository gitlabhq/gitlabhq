# frozen_string_literal: true

require 'spec_helper'

describe JiraImport::StartImportService do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project) }

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

      context 'when issues feature are disabled' do
        let_it_be(:project, reload: true) { create(:project, :issues_disabled) }

        it_behaves_like 'responds with error', 'Cannot import because issues are not available in this project.'
      end

      context 'when Jira service exists' do
        let!(:jira_service) { create(:jira_service, project: project, active: true) }

        context 'when Jira project key is not provided' do
          it_behaves_like 'responds with error', 'Unable to find Jira project to import data from.'
        end

        context 'when correct data provided' do
          let(:fake_key)  { 'some-key' }

          subject { described_class.new(user, project, fake_key).execute }

          context 'when import is already running' do
            let_it_be(:jira_import_state) { create(:jira_import_state, :started, project: project) }

            it_behaves_like 'responds with error', 'Jira import is already running.'
          end

          it 'returns success response' do
            expect(subject).to be_a(ServiceResponse)
            expect(subject).to be_success
          end

          it 'schedules jira import' do
            subject

            expect(project.latest_jira_import).to be_scheduled
          end

          it 'creates jira import data' do
            jira_import = subject.payload[:import_data]

            expect(jira_import.jira_project_xid).to eq(0)
            expect(jira_import.jira_project_name).to eq(fake_key)
            expect(jira_import.jira_project_key).to eq(fake_key)
            expect(jira_import.user).to eq(user)
          end

          it 'creates jira import label' do
            expect { subject }.to change { Label.count }.by(1)
          end

          it 'creates jira label title with correct number' do
            jira_import = subject.payload[:import_data]

            label_title = "jira-import::#{jira_import.jira_project_key}-1"
            expect(jira_import.label.title).to eq(label_title)
          end

          context 'when multiple jira imports for same jira project' do
            let!(:jira_imports) { create_list(:jira_import_state, 3, :finished, project: project, jira_project_key: fake_key)}

            it 'creates jira label title with correct number' do
              jira_import = subject.payload[:import_data]

              label_title = "jira-import::#{jira_import.jira_project_key}-4"
              expect(jira_import.label.title).to eq(label_title)
            end
          end
        end
      end
    end
  end
end
