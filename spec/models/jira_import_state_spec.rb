# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraImportState, feature_category: :integrations do
  describe "associations" do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:label) }
  end

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(AfterCommitQueue) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:jira_project_key) }
    it { is_expected.to validate_presence_of(:jira_project_name) }
    it { is_expected.to validate_presence_of(:jira_project_xid) }

    context 'when trying to run multiple imports' do
      let(:project) { create(:project) }

      context 'when project has an initial jira_import' do
        let!(:jira_import) { create(:jira_import_state, project: project) }

        it_behaves_like 'multiple running imports not allowed'
      end

      context 'when project has a scheduled jira_import' do
        let!(:jira_import) { create(:jira_import_state, :scheduled, project: project) }

        it_behaves_like 'multiple running imports not allowed'
      end

      context 'when project has a started jira_import' do
        let!(:jira_import) { create(:jira_import_state, :started, project: project) }

        it_behaves_like 'multiple running imports not allowed'
      end

      context 'when project has a failed jira_import' do
        let!(:jira_import) { create(:jira_import_state, :failed, project: project) }

        it 'returns valid' do
          new_import = build(:jira_import_state, project: project)

          expect(new_import).to be_valid
          expect(new_import.errors[:project]).to be_empty
        end
      end

      context 'when project has a finished jira_import' do
        let!(:jira_import) { create(:jira_import_state, :finished, project: project) }

        it 'returns valid' do
          new_import = build(:jira_import_state, project: project)

          expect(new_import).to be_valid
          expect(new_import.errors[:project]).to be_empty
        end
      end
    end
  end

  describe '#in_progress?' do
    context 'statuses that return in progress' do
      it_behaves_like 'in progress', :scheduled
      it_behaves_like 'in progress', :started
    end

    context 'statuses that return not in progress' do
      it_behaves_like 'not in progress', :initial
      it_behaves_like 'not in progress', :failed
      it_behaves_like 'not in progress', :finished
    end
  end

  describe 'states transition flow' do
    let(:project) { create(:project) }

    context 'when jira import is in initial state' do
      let!(:jira_import) { build(:jira_import_state, project: project) }

      it_behaves_like 'can transition', [:schedule, :do_fail]
      it_behaves_like 'cannot transition', [:start, :finish]
    end

    context 'when jira import is in scheduled state' do
      let!(:jira_import) { build(:jira_import_state, :scheduled, project: project) }

      it_behaves_like 'can transition', [:start, :do_fail]
      it_behaves_like 'cannot transition', [:finish]
    end

    context 'when jira import is in started state' do
      let!(:jira_import) { build(:jira_import_state, :started, project: project) }

      it_behaves_like 'can transition', [:finish, :do_fail]
      it_behaves_like 'cannot transition', [:schedule]
    end

    context 'when jira import is in failed state' do
      let!(:jira_import) { build(:jira_import_state, :failed, project: project) }

      it_behaves_like 'cannot transition', [:schedule, :finish, :do_fail]
    end

    context 'when jira import is in finished state' do
      let!(:jira_import) { build(:jira_import_state, :finished, project: project) }

      it_behaves_like 'cannot transition', [:schedule, :do_fail, :start]
    end

    context 'after transition to scheduled' do
      let!(:jira_import) { build(:jira_import_state, project: project) }

      it 'triggers the import job' do
        expect(Gitlab::JiraImport::Stage::StartImportWorker).to receive(:perform_async).and_return('some-job-id')

        jira_import.schedule

        expect(jira_import.jid).to eq('some-job-id')
        expect(jira_import.scheduled_at).to be_within(1.second).of(Time.current)
      end
    end

    context 'after transition to finished' do
      let!(:jira_import) { build(:jira_import_state, :started, jid: 'some-other-jid', project: project) }

      subject { jira_import.finish }

      it 'triggers the import job' do
        subject

        expect(jira_import.jid).to be_nil
      end

      it 'triggers the import job' do
        jira_import.update!(status: :scheduled)

        subject

        expect(jira_import.status).to eq('scheduled')
        expect(jira_import.jid).to eq('some-other-jid')
      end

      it 'updates the record with imported issues counts' do
        import_label = create(:label, project: project, title: 'jira-import')
        create_list(:labeled_issue, 3, project: project, labels: [import_label])

        expect(Gitlab::JiraImport).to receive(:get_import_label_id).and_return(import_label.id)
        expect(Gitlab::JiraImport).to receive(:issue_failures).and_return(2)

        subject

        expect(jira_import.total_issue_count).to eq(5)
        expect(jira_import.failed_to_import_count).to eq(2)
        expect(jira_import.imported_issues_count).to eq(3)
      end
    end
  end

  context 'ensure error_message size on save' do
    let_it_be(:project) { create(:project) }

    before do
      stub_const('JiraImportState::ERROR_MESSAGE_SIZE', 10)
    end

    context 'when jira import has no error_message' do
      let(:jira_import) { build(:jira_import_state, project: project) }

      it 'does not run the callback', :aggregate_failures do
        expect { jira_import.save! }.to change { JiraImportState.count }.by(1)
        expect(jira_import.reload.error_message).to be_nil
      end
    end

    context 'when jira import error_message does not exceed the limit' do
      let(:jira_import) { build(:jira_import_state, project: project, error_message: 'error') }

      it 'does not run the callback', :aggregate_failures do
        expect { jira_import.save! }.to change { JiraImportState.count }.by(1)
        expect(jira_import.reload.error_message).to eq('error')
      end
    end

    context 'when error_message exceeds limit' do
      let(:jira_import) { build(:jira_import_state, project: project, error_message: 'error message longer than the limit') }

      it 'truncates error_message to the limit', :aggregate_failures do
        expect { jira_import.save! }.to change { JiraImportState.count }.by(1)
        expect(jira_import.reload.error_message.size).to eq 10
      end
    end
  end
end
