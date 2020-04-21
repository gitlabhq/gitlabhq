# frozen_string_literal: true

require 'rake_helper'

describe Gitlab::ImportExport::Project::ImportTask, :request_store do
  let(:username) { 'root' }
  let(:namespace_path) { username }
  let!(:user) { create(:user, username: username) }
  let(:measurement_enabled) { false }
  let(:project) { Project.find_by_full_path("#{namespace_path}/#{project_name}") }
  let(:import_task) { described_class.new(task_params) }
  let(:task_params) do
    {
      username: username,
      namespace_path: namespace_path,
      project_path: project_name,
      file_path: file_path,
      measurement_enabled: measurement_enabled
    }
  end

  before do
    allow(Settings.uploads.object_store).to receive(:[]=).and_call_original
  end

  around do |example|
    old_direct_upload_setting     = Settings.uploads.object_store['direct_upload']
    old_background_upload_setting = Settings.uploads.object_store['background_upload']

    Settings.uploads.object_store['direct_upload']     = true
    Settings.uploads.object_store['background_upload'] = true

    example.run

    Settings.uploads.object_store['direct_upload']     = old_direct_upload_setting
    Settings.uploads.object_store['background_upload'] = old_background_upload_setting
  end

  subject { import_task.import }

  context 'when project import is valid' do
    let(:project_name) { 'import_rake_test_project' }
    let(:file_path) { 'spec/fixtures/gitlab/import_export/lightweight_project_export.tar.gz' }

    it 'performs project import successfully' do
      expect { subject }.to output(/Done!/).to_stdout
      expect { subject }.not_to raise_error
      expect(subject).to eq(true)

      expect(project.merge_requests.count).to be > 0
      expect(project.issues.count).to be > 0
      expect(project.milestones.count).to be > 0
      expect(project.import_state.status).to eq('finished')
    end

    it 'disables direct & background upload only during project creation' do
      expect_next_instance_of(Projects::GitlabProjectsImportService) do |service|
        expect(service).to receive(:execute).and_wrap_original do |m|
          expect(Settings.uploads.object_store['background_upload']).to eq(false)
          expect(Settings.uploads.object_store['direct_upload']).to eq(false)

          m.call
        end
      end

      expect(import_task).to receive(:execute_sidekiq_job).and_wrap_original do |m|
        expect(Settings.uploads.object_store['background_upload']).to eq(true)
        expect(Settings.uploads.object_store['direct_upload']).to eq(true)
        expect(Settings.uploads.object_store).not_to receive(:[]=).with('backgroud_upload', false)
        expect(Settings.uploads.object_store).not_to receive(:[]=).with('direct_upload', false)

        m.call
      end

      subject
    end

    it_behaves_like 'measurable'
  end

  context 'when project import is invalid' do
    let(:project_name) { 'import_rake_invalid_test_project' }
    let(:file_path) { 'spec/fixtures/gitlab/import_export/corrupted_project_export.tar.gz' }
    let(:not_imported_message) { /Total number of not imported relations: 1/ }

    it 'performs project import successfully' do
      expect { subject }.to output(not_imported_message).to_stdout
      expect { subject }.not_to raise_error
      expect(subject).to eq(true)

      expect(project.merge_requests).to be_empty
      expect(project.import_state.last_error).to be_nil
      expect(project.import_state.status).to eq('finished')
    end
  end
end
