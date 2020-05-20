# frozen_string_literal: true

require 'spec_helper'

describe JiraImport::StartImportService do
  include JiraServiceHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project) }
  let(:key) { 'KEY' }

  subject { described_class.new(user, project, key).execute }

  context 'when an error is returned from the project validation' do
    before do
      allow(project).to receive(:validate_jira_import_settings!)
        .and_raise(Projects::ImportService::Error, 'Jira import feature is disabled.')
    end

    it_behaves_like 'responds with error', 'Jira import feature is disabled.'
  end

  context 'when project validation is ok' do
    let!(:jira_service) { create(:jira_service, project: project, active: true) }

    before do
      stub_jira_service_test
      allow(project).to receive(:validate_jira_import_settings!)
    end

    context 'when Jira project key is not provided' do
      let(:key) { '' }

      it_behaves_like 'responds with error', 'Unable to find Jira project to import data from.'
    end

    context 'when correct data provided' do
      let(:fake_key)  { 'some-key' }

      subject { described_class.new(user, project, fake_key).execute }

      context 'when import is already running' do
        let_it_be(:jira_import_state) { create(:jira_import_state, :started, project: project) }

        it_behaves_like 'responds with error', 'Jira import is already running.'
      end

      context 'when everything is ok' do
        it 'returns success response' do
          expect(subject).to be_a(ServiceResponse)
          expect(subject).to be_success
        end

        it 'schedules Jira import' do
          subject

          expect(project.latest_jira_import).to be_scheduled
        end

        it 'creates Jira import data' do
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
