# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::JiraImport::Stage::StartImportWorker do
  let(:project) { create(:project, import_type: 'jira') }
  let(:worker) { described_class.new }
  let(:jid) { '12345678' }

  describe 'modules' do
    it_behaves_like 'include import workers modules'
  end

  describe '#perform' do
    context 'when feature flag not enabled' do
      before do
        stub_feature_flags(jira_issue_import: false)
      end

      it 'exits because import not allowed' do
        expect(Gitlab::JiraImport::Stage::ImportLabelsWorker).not_to receive(:perform_async)

        worker.perform(project.id)
      end
    end

    context 'when feature flag enabled' do
      let(:symbol_keys_project) do
        { key: 'AA', scheduled_at: 2.days.ago.strftime('%Y-%m-%d %H:%M:%S'), scheduled_by: { 'user_id' => 1, 'name' => 'tester1' } }
      end
      let(:import_data) { JiraImportData.new( data: { 'jira' => { JiraImportData::FORCE_IMPORT_KEY => true, projects: [symbol_keys_project] } }) }

      before do
        stub_feature_flags(jira_issue_import: true)
      end

      context 'when import is not scheduled' do
        let(:project) { create(:project, import_type: 'jira') }
        let(:import_state) { create(:import_state, project: project, status: :none, jid: jid) }

        it 'exits because import not started' do
          expect(Gitlab::JiraImport::Stage::ImportLabelsWorker).not_to receive(:perform_async)

          worker.perform(project.id)
        end
      end

      context 'when import is scheduled' do
        let(:import_state) { create(:import_state, status: :scheduled, jid: jid) }
        let(:project) { create(:project, import_type: 'jira', import_state: import_state) }

        context 'when this is a mirror sync in a jira imported project' do
          it 'exits early' do
            expect(Gitlab::Import::SetAsyncJid).not_to receive(:set_jid)
            expect(Gitlab::JiraImport::Stage::ImportLabelsWorker).not_to receive(:perform_async)

            worker.perform(project.id)
          end
        end

        context 'when scheduled import is a hard triggered jira import and not a mirror' do
          let!(:project) { create(:project, import_type: 'jira', import_data: import_data, import_state: import_state) }

          it 'advances to importing labels' do
            expect(Gitlab::JiraImport::Stage::ImportLabelsWorker).to receive(:perform_async)

            worker.perform(project.id)
          end
        end
      end

      context 'when import is started' do
        let!(:import_state) { create(:import_state, status: :started, jid: jid) }
        let!(:project) { create(:project, import_type: 'jira', import_data: import_data, import_state: import_state) }

        context 'when this is the same worker that stated import' do
          it 'advances to importing labels' do
            allow(worker).to receive(:jid).and_return(jid)
            expect(Gitlab::JiraImport::Stage::ImportLabelsWorker).to receive(:perform_async)

            worker.perform(project.id)
          end
        end

        context 'when this is a different worker that stated import' do
          it 'advances to importing labels' do
            allow(worker).to receive(:jid).and_return('87654321')
            expect(Gitlab::JiraImport::Stage::ImportLabelsWorker).not_to receive(:perform_async)

            worker.perform(project.id)
          end
        end
      end

      context 'when import is finished' do
        let!(:import_state) { create(:import_state, status: :finished, jid: jid) }
        let!(:project) { create(:project, import_type: 'jira', import_data: import_data, import_state: import_state) }

        it 'advances to importing labels' do
          allow(worker).to receive(:jid).and_return(jid)
          expect(Gitlab::JiraImport::Stage::ImportLabelsWorker).not_to receive(:perform_async)

          worker.perform(project.id)
        end
      end
    end
  end
end
