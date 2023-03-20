# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::JiraImport::Stage::StartImportWorker, feature_category: :importers do
  let_it_be(:project) { create(:project, import_type: 'jira') }
  let_it_be(:jid) { '12345678' }

  let(:worker) { described_class.new }

  describe 'modules' do
    it_behaves_like 'include import workers modules'
  end

  describe '#perform' do
    let_it_be(:jira_import, reload: true) { create(:jira_import_state, project: project, jid: jid) }

    context 'when import is not scheduled' do
      it 'exits because import not started' do
        expect(Gitlab::JiraImport::Stage::ImportLabelsWorker).not_to receive(:perform_async)

        worker.perform(project.id)
      end
    end

    context 'when import is scheduled' do
      before do
        jira_import.schedule!
      end

      it 'advances to importing labels' do
        expect(Gitlab::JiraImport::Stage::ImportLabelsWorker).to receive(:perform_async)

        worker.perform(project.id)
      end
    end

    context 'when import is started' do
      before do
        jira_import.update!(status: :started)
      end

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
      before do
        jira_import.update!(status: :finished)
      end

      it 'advances to importing labels' do
        allow(worker).to receive(:jid).and_return(jid)
        expect(Gitlab::JiraImport::Stage::ImportLabelsWorker).not_to receive(:perform_async)

        worker.perform(project.id)
      end
    end
  end
end
