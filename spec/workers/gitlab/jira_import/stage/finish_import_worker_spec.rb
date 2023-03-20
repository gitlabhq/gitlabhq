# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::JiraImport::Stage::FinishImportWorker, feature_category: :importers do
  let_it_be(:project) { create(:project) }
  let_it_be(:worker) { described_class.new }

  describe 'modules' do
    it_behaves_like 'include import workers modules'
  end

  describe '#perform' do
    let_it_be(:jira_import, reload: true) { create(:jira_import_state, :scheduled, project: project) }

    context 'when import did not start' do
      it_behaves_like 'cannot do Jira import'
    end

    context 'when import started' do
      let_it_be(:import_label) { create(:label, project: project, title: 'jira-import') }
      let_it_be(:imported_issues) { create_list(:labeled_issue, 3, project: project, labels: [import_label]) }

      before do
        expect(Gitlab::JiraImport).to receive(:get_import_label_id).and_return(import_label.id)
        expect(Gitlab::JiraImport).to receive(:issue_failures).and_return(2)

        jira_import.start!
        worker.perform(project.id)
      end

      it 'changes import state to finished' do
        expect(project.jira_import_status).to eq('finished')
      end

      it 'saves imported issues counts' do
        latest_jira_import = project.latest_jira_import
        expect(latest_jira_import.total_issue_count).to eq(5)
        expect(latest_jira_import.failed_to_import_count).to eq(2)
        expect(latest_jira_import.imported_issues_count).to eq(3)
      end
    end
  end
end
