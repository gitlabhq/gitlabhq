# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::JiraImport::Stage::FinishImportWorker do
  let_it_be(:project) { create(:project) }
  let_it_be(:worker) { described_class.new }

  describe 'modules' do
    it_behaves_like 'include import workers modules'
  end

  describe '#perform' do
    context 'when feature flag enabled' do
      before do
        stub_feature_flags(jira_issue_import: false)
      end

      it_behaves_like 'cannot do jira import'
    end

    context 'when feature flag enabled' do
      let_it_be(:jira_import) { create(:jira_import_state, :scheduled, project: project) }

      before do
        stub_feature_flags(jira_issue_import: true)
      end

      context 'when import did not start' do
        it_behaves_like 'cannot do jira import'
      end

      context 'when import started' do
        before do
          jira_import.start!
        end

        it 'changes import state to finished' do
          worker.perform(project.id)

          expect(project.jira_import_status).to eq('finished')
        end
      end
    end
  end
end
