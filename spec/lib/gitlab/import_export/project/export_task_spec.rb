# frozen_string_literal: true

require 'rake_helper'

describe Gitlab::ImportExport::Project::ExportTask do
  let_it_be(:username) { 'root' }
  let(:namespace_path) { username }
  let_it_be(:user) { create(:user, username: username) }
  let(:measurement_enabled) { false }
  let(:file_path) { 'spec/fixtures/gitlab/import_export/test_project_export.tar.gz' }
  let(:project) { create(:project, creator: user, namespace: user.namespace) }
  let(:project_name) { project.name }

  let(:task_params) do
    {
      username: username,
      namespace_path: namespace_path,
      project_path: project_name,
      file_path: file_path,
      measurement_enabled: measurement_enabled
    }
  end

  subject { described_class.new(task_params).export }

  context 'when project is found' do
    let(:project) { create(:project, creator: user, namespace: user.namespace) }

    around do |example|
      example.run
    ensure
      File.delete(file_path)
    end

    it 'performs project export successfully' do
      expect { subject }.to output(/Done!/).to_stdout

      expect(subject).to eq(true)

      expect(File).to exist(file_path)
    end

    it_behaves_like 'measurable'
  end

  context 'when project is not found' do
    let(:project_name) { 'invalid project name' }

    it 'logs an error' do
      expect { subject }.to output(/Project with path: #{project_name} was not found. Please provide correct project path/).to_stdout
    end

    it 'returns false' do
      expect(subject).to eq(false)
    end
  end

  context 'when file path is invalid' do
    let(:file_path) { '/invalid_file_path/test_project_export.tar.gz' }

    it 'logs an error' do
      expect { subject }.to output(/Invalid file path: #{file_path}. Please provide correct file path/ ).to_stdout
    end

    it 'returns false' do
      expect(subject).to eq(false)
    end
  end
end
