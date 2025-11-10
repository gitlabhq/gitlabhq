# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:artifacts namespace rake task', :silence_stdout, feature_category: :job_artifacts do
  before(:context) do
    Rake.application.rake_require 'tasks/gitlab/artifacts/fix_artifact_filepath'
  end

  let(:desired_file_name) { 'desired_name.zip' }
  let(:remote_file_name)  { 'remote_name.zip' }
  let(:local_path)        { "/local/path/#{remote_file_name}" }
  let(:file_final_path)   { "/remote/path/#{remote_file_name}" }

  let(:renamed_files) { [] }
  let(:relation_class) do
    Class.new do
      include EachBatch
    end
  end

  let(:relation) { class_double(relation_class, each_batch: nil) }

  let(:artifact) do
    instance_double(
      Ci::JobArtifact,
      file_final_path: file_final_path,
      file: uploader_double,
      file_identifier: desired_file_name,
      id: 1,
      size: 0
    )
  end

  let(:uploader_double) do
    instance_double(
      JobArtifactUploader,
      path: local_path
    )
  end

  before do
    allow(artifact).to receive(:[]).with('file').and_return(desired_file_name)
    allow(artifact.file).to receive(:path).and_return("/local/path/#{remote_file_name}")

    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with("/local/path/#{desired_file_name}").and_return(desired_exists)
    allow(File).to receive(:exist?).with(local_path).and_return(remote_exists)

    allow(File).to receive(:rename) do |old_path, new_path|
      renamed_files << [old_path, new_path]
    end

    allow(relation).to receive(:each_batch).and_yield([artifact])

    allow(Ci::JobArtifact).to receive(:with_files_stored_locally).and_return(relation)
  end

  describe 'gitlab:artifacts:migrate' do
    subject(:task) { run_rake_task('gitlab:artifacts:fix_artifact_filepath') }

    context 'when file needs to be renamed' do
      let(:desired_exists) { false }
      let(:remote_exists) { true }

      it 'renames the file' do
        task
        expect(renamed_files).to match_array([[local_path, "/local/path/#{desired_file_name}"]])
      end
    end
  end
end
