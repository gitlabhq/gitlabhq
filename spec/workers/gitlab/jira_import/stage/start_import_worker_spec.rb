# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::JiraImport::Stage::StartImportWorker do
  let(:project) { create(:project) }
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

    context 'when feature flag not enabled' do
      before do
        stub_feature_flags(jira_issue_import: true)
      end

      context 'when import is not scheudled' do
        let!(:import_state) { create(:import_state, project: project, status: :none, jid: jid) }

        it 'exits because import not started' do
          expect(Gitlab::JiraImport::Stage::ImportLabelsWorker).not_to receive(:perform_async)

          worker.perform(project.id)
        end
      end

      context 'when import is scheduled' do
        let!(:import_state) { create(:import_state, project: project, status: :scheduled, jid: jid) }

        it 'advances to importing labels' do
          expect(Gitlab::JiraImport::Stage::ImportLabelsWorker).to receive(:perform_async)

          worker.perform(project.id)
        end
      end

      context 'when import is started' do
        let!(:import_state) { create(:import_state, project: project, status: :started, jid: jid) }

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
        let!(:import_state) { create(:import_state, project: project, status: :finished, jid: jid) }

        it 'advances to importing labels' do
          allow(worker).to receive(:jid).and_return(jid)
          expect(Gitlab::JiraImport::Stage::ImportLabelsWorker).not_to receive(:perform_async)

          worker.perform(project.id)
        end
      end
    end
  end
end
