# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Project::ExportTask, :silence_stdout, feature_category: :importers do
  let_it_be(:username) { 'root' }
  let(:namespace_path) { username }
  let_it_be(:user) { create(:user, username: username) }

  let(:measurement_enabled) { false }
  let(:file_path) { 'spec/fixtures/gitlab/import_export/test_project_export.tar.gz' }
  let(:project) { create(:project, creator: user, namespace: user.namespace) }
  let(:project_path) { project.path }
  let(:rake_task) { described_class.new(task_params) }

  let(:task_params) do
    {
      username: username,
      namespace_path: namespace_path,
      project_path: project_path,
      file_path: file_path,
      measurement_enabled: measurement_enabled
    }
  end

  subject { rake_task.export }

  context 'when project is found' do
    let(:project) { create(:project, creator: user, namespace: user.namespace) }

    around do |example|
      example.run
    ensure
      FileUtils.rm_f(file_path)
    end

    include_context 'rake task object storage shared context'

    it_behaves_like 'rake task with disabled object_storage', ::Projects::ImportExport::ExportService, :success

    it 'performs project export successfully' do
      expect { subject }.to output(/Done!/).to_stdout

      expect(subject).to eq(true)

      expect(File).to exist(file_path)
    end
  end

  context 'when project is not found' do
    let(:project_path) { 'invalid project path' }

    it 'logs an error' do
      expect { subject }.to output(/Project with path: #{project_path} was not found. Please provide correct project path/).to_stdout
    end

    it 'returns false' do
      expect(subject).to eq(false)
    end
  end

  context 'when file path is invalid' do
    let(:file_path) { '/invalid_file_path/test_project_export.tar.gz' }

    it 'logs an error' do
      expect { subject }.to output(/Invalid file path: #{file_path}. Please provide correct file path/).to_stdout
    end

    it 'returns false' do
      expect(subject).to eq(false)
    end
  end

  context 'when after export strategy fails' do
    before do
      allow_next_instance_of(Gitlab::ImportExport::AfterExportStrategies::MoveFileStrategy) do |after_export_strategy|
        allow(after_export_strategy).to receive(:strategy_execute).and_raise(Gitlab::ImportExport::AfterExportStrategies::BaseAfterExportStrategy::StrategyError)
      end
    end

    it 'error is logged' do
      expect(rake_task).to receive(:error).and_call_original

      expect(subject).to eq(false)
    end
  end

  context 'when saving services fail' do
    before do
      allow_next_instance_of(::Projects::ImportExport::ExportService) do |service|
        allow(service).to receive(:execute).and_raise(Gitlab::ImportExport::Error)
      end
    end

    it 'error is logged' do
      expect(rake_task).to receive(:error).and_call_original

      expect(subject).to eq(false)
    end
  end
end
