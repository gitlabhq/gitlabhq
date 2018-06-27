require 'spec_helper'

describe ProjectExportWorker do
  let!(:user) { create(:user) }
  let!(:project) { create(:project) }

  subject { described_class.new }

  describe '#perform' do
    context 'when it succeeds' do
      it 'calls the ExportService' do
        expect_any_instance_of(::Projects::ImportExport::ExportService).to receive(:execute)

        subject.perform(user.id, project.id, { 'klass' => 'Gitlab::ImportExport::AfterExportStrategies::DownloadNotificationStrategy' })
      end
    end

    context 'when it fails' do
      it 'raises an exception when params are invalid' do
        expect_any_instance_of(::Projects::ImportExport::ExportService).not_to receive(:execute)

        expect { subject.perform(1234, project.id, {}) }.to raise_exception(ActiveRecord::RecordNotFound)
        expect { subject.perform(user.id, 1234, {}) }.to raise_exception(ActiveRecord::RecordNotFound)
        expect { subject.perform(user.id, project.id, { 'klass' => 'Whatever' }) }.to raise_exception(Gitlab::ImportExport::AfterExportStrategyBuilder::StrategyNotFoundError)
      end
    end
  end
end
