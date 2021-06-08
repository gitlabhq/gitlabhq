# frozen_string_literal: true

require 'rake_helper'

RSpec.describe Gitlab::ImportExport::Project::ImportTask, :request_store, :silence_stdout do
  let(:username) { 'root' }
  let(:namespace_path) { username }
  let!(:user) { create(:user, username: username) }
  let(:measurement_enabled) { false }
  let(:project) { Project.find_by_full_path("#{namespace_path}/#{project_name}") }
  let(:rake_task) { described_class.new(task_params) }
  let(:task_params) do
    {
      username: username,
      namespace_path: namespace_path,
      project_path: project_name,
      file_path: file_path,
      measurement_enabled: measurement_enabled
    }
  end

  subject { rake_task.import }

  context 'when project import is valid' do
    let(:project_name) { 'import_rake_test_project' }
    let(:file_path) { 'spec/fixtures/gitlab/import_export/lightweight_project_export.tar.gz' }

    include_context 'rake task object storage shared context'

    it_behaves_like 'rake task with disabled object_storage', ::Projects::GitlabProjectsImportService, :execute_sidekiq_job

    it 'performs project import successfully' do
      expect { subject }.to output(/Done!/).to_stdout
      expect { subject }.not_to raise_error
      expect(subject).to eq(true)

      expect(project.merge_requests.count).to be > 0
      expect(project.issues.count).to be > 0
      expect(project.milestones.count).to be > 0
      expect(project.import_state.status).to eq('finished')
    end
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
