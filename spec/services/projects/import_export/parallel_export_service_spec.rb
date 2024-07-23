# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportExport::ParallelExportService, feature_category: :importers do
  let_it_be(:user) { create(:user) }

  let(:export_job) { create(:project_export_job) }
  let(:after_export_strategy) { Gitlab::ImportExport::AfterExportStrategies::DownloadNotificationStrategy.new }
  let(:project) { export_job.project }

  before do
    allow_next_instance_of(Gitlab::ImportExport::Project::ExportedRelationsMerger) do |saver|
      allow(saver).to receive(:save).and_return(true)
    end

    allow_next_instance_of(Gitlab::ImportExport::VersionSaver) do |saver|
      allow(saver).to receive(:save).and_return(true)
    end
  end

  describe '#execute' do
    subject(:service) { described_class.new(export_job, user, after_export_strategy) }

    it 'creates a project export archive file' do
      expect(Gitlab::ImportExport::Saver).to receive(:save)
        .with(exportable: project, shared: project.import_export_shared, user: user)

      service.execute
    end

    it 'logs export progress' do
      allow(Gitlab::ImportExport::Saver).to receive(:save).and_return(true)

      logger = service.instance_variable_get(:@logger)
      messages = [
        'Parallel project export started',
        'Parallel project export - Gitlab::ImportExport::VersionSaver saver started',
        'Parallel project export - Gitlab::ImportExport::Project::ExportedRelationsMerger saver started',
        'Parallel project export finished successfully'
      ]
      messages.each do |message|
        expect(logger).to receive(:info).ordered.with(hash_including(message: message))
      end

      service.execute
    end

    it 'executes after export stragegy on export success' do
      allow(Gitlab::ImportExport::Saver).to receive(:save).and_return(true)

      expect(after_export_strategy).to receive(:execute)

      service.execute
    end

    it 'ensures files are cleaned up' do
      shared = project.import_export_shared
      FileUtils.mkdir_p(shared.archive_path)
      FileUtils.mkdir_p(shared.export_path)

      allow(Gitlab::ImportExport::Saver).to receive(:save).and_raise(StandardError)

      expect { service.execute }.to raise_error(StandardError)

      expect(File.exist?(shared.export_path)).to eq(false)
      expect(File.exist?(shared.archive_path)).to eq(false)
    end

    context 'when export fails' do
      it 'notifies the error to the user' do
        allow(Gitlab::ImportExport::Saver).to receive(:save).and_return(false)

        allow(project.import_export_shared).to receive(:errors).and_return(['Error'])

        expect_next_instance_of(NotificationService) do |instance|
          expect(instance).to receive(:project_not_exported).with(project, user, ['Error'])
        end

        service.execute
      end
    end

    context 'when after export stragegy fails' do
      it 'notifies the error to the user' do
        allow(Gitlab::ImportExport::Saver).to receive(:save).and_return(true)
        allow(after_export_strategy).to receive(:execute).and_return(false)
        allow(project.import_export_shared).to receive(:errors).and_return(['Error'])

        expect_next_instance_of(NotificationService) do |instance|
          expect(instance).to receive(:project_not_exported).with(project, user, ['Error'])
        end

        service.execute
      end
    end
  end
end
