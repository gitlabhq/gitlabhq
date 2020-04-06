# frozen_string_literal: true

require 'spec_helper'

describe JiraImportState do
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
        let!(:jira_import) { create(:jira_import_state, project: project)}

        it_behaves_like 'multiple running imports not allowed'
      end

      context 'when project has a scheduled jira_import' do
        let!(:jira_import) { create(:jira_import_state, :scheduled, project: project)}

        it_behaves_like 'multiple running imports not allowed'
      end

      context 'when project has a started jira_import' do
        let!(:jira_import) { create(:jira_import_state, :started, project: project)}

        it_behaves_like 'multiple running imports not allowed'
      end

      context 'when project has a failed jira_import' do
        let!(:jira_import) { create(:jira_import_state, :failed, project: project)}

        it 'returns valid' do
          new_import = build(:jira_import_state, project: project)

          expect(new_import).to be_valid
          expect(new_import.errors[:project]).to be_empty
        end
      end

      context 'when project has a finished jira_import' do
        let!(:jira_import) { create(:jira_import_state, :finished, project: project)}

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
      let!(:jira_import) { build(:jira_import_state, project: project)}

      it_behaves_like 'can transition', [:schedule, :do_fail]
      it_behaves_like 'cannot transition', [:start, :finish]
    end

    context 'when jira import is in scheduled state' do
      let!(:jira_import) { build(:jira_import_state, :scheduled, project: project)}

      it_behaves_like 'can transition', [:start, :do_fail]
      it_behaves_like 'cannot transition', [:finish]
    end

    context 'when jira import is in started state' do
      let!(:jira_import) { build(:jira_import_state, :started, project: project)}

      it_behaves_like 'can transition', [:finish, :do_fail]
      it_behaves_like 'cannot transition', [:schedule]
    end

    context 'when jira import is in failed state' do
      let!(:jira_import) { build(:jira_import_state, :failed, project: project)}

      it_behaves_like 'cannot transition', [:schedule, :finish, :do_fail]
    end

    context 'when jira import is in finished state' do
      let!(:jira_import) { build(:jira_import_state, :finished, project: project)}

      it_behaves_like 'cannot transition', [:schedule, :do_fail, :start]
    end

    context 'after transition to scheduled' do
      let!(:jira_import) { build(:jira_import_state, project: project)}

      it 'triggers the import job' do
        expect(Gitlab::JiraImport::Stage::StartImportWorker).to receive(:perform_async).and_return('some-job-id')

        jira_import.schedule

        expect(jira_import.jid).to eq('some-job-id')
      end
    end

    context 'after transition to finished' do
      let!(:jira_import) { build(:jira_import_state, :started, jid: 'some-other-jid', project: project)}

      it 'triggers the import job' do
        jira_import.finish

        expect(jira_import.jid).to be_nil
      end

      it 'triggers the import job' do
        jira_import.update!(status: :scheduled)

        jira_import.finish

        expect(jira_import.status).to eq('scheduled')
        expect(jira_import.jid).to eq('some-other-jid')
      end
    end
  end
end
