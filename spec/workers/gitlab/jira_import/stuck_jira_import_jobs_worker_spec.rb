# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::JiraImport::StuckJiraImportJobsWorker, feature_category: :importers do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:worker) { described_class.new }

  describe 'with scheduled Jira import' do
    it_behaves_like 'stuck import job detection' do
      let(:import_state) { create(:jira_import_state, :scheduled, project: project) }

      before do
        import_state.update!(jid: '123')
      end
    end
  end

  describe 'with started jira import' do
    it_behaves_like 'stuck import job detection' do
      let(:import_state) { create(:jira_import_state, :started, project: project) }

      before do
        import_state.update!(jid: '123')
      end
    end
  end

  describe 'with failed jira import' do
    let(:import_state) { create(:jira_import_state, :failed, project: project) }

    it 'detects no stuck jobs' do
      expect(worker).to receive(:track_metrics).with(0, 0)

      worker.perform
    end
  end
end
