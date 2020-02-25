# frozen_string_literal: true

require 'rake_helper'

describe 'gitlab:import_export:export rake task' do
  let(:username) { 'root' }
  let(:namespace_path) { username }
  let!(:user) { create(:user, username: username) }
  let(:measurement_enabled) { false }
  let(:task_params) { [username, namespace_path, project_name, archive_path, measurement_enabled] }

  before do
    Rake.application.rake_require('tasks/gitlab/import_export/export')
  end

  subject { run_rake_task('gitlab:import_export:export', task_params) }

  context 'when project is found' do
    let(:project) { create(:project, creator: user, namespace: user.namespace) }
    let(:project_name) { project.name }
    let(:archive_path) { 'spec/fixtures/gitlab/import_export/test_project_export.tar.gz' }

    around do |example|
      example.run
    ensure
      File.delete(archive_path)
    end

    it 'performs project export successfully' do
      expect { subject }.to output(/Done!/).to_stdout

      expect(File).to exist(archive_path)
    end

    it_behaves_like 'measurable'
  end
end
