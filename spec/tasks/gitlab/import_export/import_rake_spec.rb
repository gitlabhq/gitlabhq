# frozen_string_literal: true

require 'rake_helper'

describe 'gitlab:import_export:import rake task', :sidekiq do
  let(:username) { 'root' }
  let(:namespace_path) { username }
  let!(:user) { create(:user, username: username) }
  let(:task_params) { [username, namespace_path, project_name, archive_path] }
  let(:project) { Project.find_by_full_path("#{namespace_path}/#{project_name}") }

  before do
    Rake.application.rake_require('tasks/gitlab/import_export/import')
    allow(Settings.uploads.object_store).to receive(:[]=).and_call_original
    allow_any_instance_of(GitlabProjectImport).to receive(:exit)
      .and_raise(RuntimeError, 'exit not handled')
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

  subject { run_rake_task('gitlab:import_export:import', task_params) }

  context 'when project import is valid' do
    let(:project_name) { 'import_rake_test_project' }
    let(:archive_path) { 'spec/fixtures/gitlab/import_export/lightweight_project_export.tar.gz' }

    it 'performs project import successfully' do
      expect { subject }.to output(/Done!/).to_stdout
      expect { subject }.not_to raise_error

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

      expect_next_instance_of(GitlabProjectImport) do |importer|
        expect(importer).to receive(:execute_sidekiq_job).and_wrap_original do |m|
          expect(Settings.uploads.object_store['background_upload']).to eq(true)
          expect(Settings.uploads.object_store['direct_upload']).to eq(true)
          expect(Settings.uploads.object_store).not_to receive(:[]=).with('backgroud_upload', false)
          expect(Settings.uploads.object_store).not_to receive(:[]=).with('direct_upload', false)

          m.call
        end
      end

      subject
    end
  end

  context 'when project import is invalid' do
    let(:project_name) { 'import_rake_invalid_test_project' }
    let(:archive_path) { 'spec/fixtures/gitlab/import_export/corrupted_project_export.tar.gz' }
    let(:not_imported_message) { /Total number of not imported relations: 1/ }
    let(:error) { /Validation failed: Notes is invalid/ }

    context 'when import_graceful_failures feature flag is enabled' do
      before do
        stub_feature_flags(import_graceful_failures: true)
      end

      it 'performs project import successfully' do
        expect { subject }.to output(not_imported_message).to_stdout
        expect { subject }.not_to raise_error

        expect(project.merge_requests).to be_empty
        expect(project.import_state.last_error).to be_nil
        expect(project.import_state.status).to eq('finished')
      end
    end

    context 'when import_graceful_failures feature flag is disabled' do
      before do
        stub_feature_flags(import_graceful_failures: false)
      end

      it 'fails project import with an error' do
        # Catch exit call, and raise exception instead
        expect_any_instance_of(GitlabProjectImport).to receive(:exit)
          .with(1).and_raise(SystemExit)

        expect { subject }.to raise_error(SystemExit).and output(error).to_stdout

        expect(project.merge_requests).to be_empty
        expect(project.import_state.last_error).to match(error)
        expect(project.import_state.status).to eq('failed')
      end
    end
  end
end
