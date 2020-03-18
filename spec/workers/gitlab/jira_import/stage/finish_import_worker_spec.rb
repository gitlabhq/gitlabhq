# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::JiraImport::Stage::FinishImportWorker do
  let(:project) { create(:project) }
  let(:worker) { described_class.new }

  describe 'modules' do
    it_behaves_like 'include import workers modules'
  end

  describe '#perform' do
    context 'when feature flag enabled' do
      before do
        stub_feature_flags(jira_issue_import: false)
      end

      it_behaves_like 'exit import not started'
    end

    context 'when feature flag enabled' do
      before do
        stub_feature_flags(jira_issue_import: true)
      end

      context 'when import did not start' do
        let!(:import_state) { create(:import_state, project: project) }

        it_behaves_like 'exit import not started'
      end

      context 'when import started' do
        let(:imported_jira_project) do
          JiraImportData::JiraProjectDetails.new('xx', Time.now.strftime('%Y-%m-%d %H:%M:%S'), { user_id: 1, name: 'root' })
        end
        let(:jira_import_data) do
          data = JiraImportData.new
          data << imported_jira_project
          data.force_import!
          data
        end
        let(:import_state) { create(:import_state, status: :started) }
        let(:project) { create(:project, import_type: 'jira', import_data: jira_import_data, import_state: import_state) }

        it 'changes import state to finished' do
          worker.perform(project.id)

          expect(project.reload.import_state.status).to eq "finished"
        end

        it 'removes force-import flag' do
          expect(project.reload.import_data.data['jira'][JiraImportData::FORCE_IMPORT_KEY]).to be true

          worker.perform(project.id)

          expect(project.reload.import_data.data['jira'][JiraImportData::FORCE_IMPORT_KEY]).to be nil
          expect(project.reload.import_data.data['jira']).not_to be nil
        end
      end
    end
  end
end
