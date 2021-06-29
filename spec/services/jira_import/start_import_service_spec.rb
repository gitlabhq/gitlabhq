# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraImport::StartImportService do
  include JiraServiceHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project) }

  let(:key) { 'KEY' }
  let(:mapping) do
    [
      { jira_account_id: 'abc', gitlab_id: 12 },
      { jira_account_id: 'def', gitlab_id: nil },
      { jira_account_id: nil, gitlab_id: 1 }
    ]
  end

  subject { described_class.new(user, project, key, mapping).execute }

  context 'when an error is returned from the project validation' do
    before do
      allow(Gitlab::JiraImport).to receive(:validate_project_settings!)
        .and_raise(Projects::ImportService::Error, 'Jira import feature is disabled.')
    end

    it_behaves_like 'responds with error', 'Jira import feature is disabled.'
  end

  context 'when project validation is ok' do
    let!(:jira_integration) { create(:jira_integration, project: project, active: true) }

    before do
      stub_jira_integration_test
      allow(Gitlab::JiraImport).to receive(:validate_project_settings!)
    end

    context 'when Jira project key is not provided' do
      let(:key) { '' }

      it_behaves_like 'responds with error', 'Unable to find Jira project to import data from.'
    end

    context 'when correct data provided' do
      let(:fake_key)  { 'some-key' }

      subject { described_class.new(user, project, fake_key, mapping).execute }

      context 'when import is already running' do
        let_it_be(:jira_import_state) { create(:jira_import_state, :started, project: project) }

        it_behaves_like 'responds with error', 'Jira import is already running.'
      end

      context 'when an error is raised while scheduling import' do
        before do
          expect_next_instance_of(JiraImportState) do |jira_impport|
            expect(jira_impport).to receive(:schedule!).and_raise(Projects::ImportService::Error, 'Unexpected failure.')
          end
        end

        it_behaves_like 'responds with error', 'Unexpected failure.'

        it 'saves the error message' do
          subject

          expect(JiraImportState.last.error_message).to eq('Unexpected failure.')
        end
      end

      context 'when everything is ok' do
        context 'with complete mapping' do
          before do
            expect(Gitlab::JiraImport).to receive(:cache_users_mapping).with(project.id, { 'abc' => 12 })
          end

          it 'returns success response' do
            expect(subject).to be_a(ServiceResponse)
            expect(subject).to be_success
          end

          it 'schedules Jira import' do
            subject

            expect(project.latest_jira_import).to be_scheduled
          end

          it 'creates Jira import data', :aggregate_failures do
            jira_import = subject.payload[:import_data]

            expect(jira_import.jira_project_xid).to eq(0)
            expect(jira_import.jira_project_name).to eq(fake_key)
            expect(jira_import.jira_project_key).to eq(fake_key)
            expect(jira_import.user).to eq(user)
          end

          it 'creates Jira import label' do
            expect { subject }.to change { Label.count }.by(1)
          end

          it 'creates Jira label title with correct number' do
            jira_import = subject.payload[:import_data]
            label_title = "jira-import::#{jira_import.jira_project_key}-1"

            expect(jira_import.label.title).to eq(label_title)
          end
        end

        context 'when mapping is nil' do
          let(:mapping) { nil }

          it 'returns success response' do
            expect(Gitlab::JiraImport).not_to receive(:cache_users_mapping)

            expect(subject).to be_a(ServiceResponse)
            expect(subject).to be_success
          end
        end

        context 'when no mapping value is complete' do
          let(:mapping) do
            [
              { jira_account_id: 'def', gitlab_id: nil },
              { jira_account_id: nil, gitlab_id: 1 }
            ]
          end

          it 'returns success response' do
            expect(Gitlab::JiraImport).not_to receive(:cache_users_mapping)

            expect(subject).to be_a(ServiceResponse)
            expect(subject).to be_success
          end
        end
      end

      context 'when multiple Jira imports for same Jira project' do
        let!(:jira_imports) { create_list(:jira_import_state, 3, :finished, project: project, jira_project_key: fake_key)}

        it 'creates Jira label title with correct number' do
          jira_import = subject.payload[:import_data]
          label_title = "jira-import::#{jira_import.jira_project_key}-4"

          expect(jira_import.label.title).to eq(label_title)
        end
      end
    end
  end
end
