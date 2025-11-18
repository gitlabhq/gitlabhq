# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::LocalAndRemoteStorageMigration::FilePathFixer, feature_category: :job_artifacts do
  let(:artifact) do
    instance_double(
      Ci::JobArtifact,
      file_final_path: file_final_path,
      file: uploader_double,
      file_identifier: desired_file_name
    )
  end

  let(:uploader_double) do
    instance_double(
      JobArtifactUploader,
      path: local_path
    )
  end

  let(:desired_file_name) { 'desired_name.zip' }
  let(:remote_file_name)  { 'remote_name.zip' }
  let(:local_path)        { "/local/path/#{remote_file_name}" }
  let(:file_final_path)   { "/remote/path/#{remote_file_name}" }

  let(:renamed_files) { [] }

  before do
    allow(artifact).to receive(:[]).with('file').and_return(desired_file_name)
    allow(artifact.file).to receive(:path).and_return("/local/path/#{remote_file_name}")

    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with("/local/path/#{desired_file_name}").and_return(desired_exists)
    allow(File).to receive(:exist?).with(local_path).and_return(remote_exists)

    allow(File).to receive(:rename) do |old_path, new_path|
      renamed_files << [old_path, new_path]
    end
  end

  describe '.fix_file_path!' do
    subject(:fix_file_path) { described_class.fix_file_path!(artifact) }

    context 'when file_final_path is blank' do
      let(:file_final_path) { nil }
      let(:desired_exists) { false }
      let(:remote_exists) { true }

      it 'does nothing' do
        expect(fix_file_path).to be_nil
        expect(renamed_files).to be_empty
      end
    end

    context 'when desired file name matches remote file name' do
      let(:desired_file_name) { 'desired_name.zip' }
      let(:remote_file_name) { 'desired_name.zip' }

      let(:desired_exists) { false }
      let(:remote_exists) { true }

      it 'does nothing' do
        expect(fix_file_path).to be_nil
        expect(renamed_files).to be_empty
      end
    end

    context 'when desired file already exists locally' do
      let(:desired_exists) { true }
      let(:remote_exists) { true }

      it 'does nothing' do
        expect(fix_file_path).to be_nil
        expect(renamed_files).to be_empty
      end
    end

    context 'when file needs to be renamed' do
      let(:desired_exists) { false }
      let(:remote_exists) { true }

      it 'renames the file' do
        is_expected.to eq("/local/path/#{desired_file_name}")
        expect(renamed_files).to match_array([[local_path, "/local/path/#{desired_file_name}"]])
      end
    end

    context 'when remote file does not exist' do
      let(:desired_exists) { false }
      let(:remote_exists) { false }

      it 'does nothing' do
        expect(fix_file_path).to be_nil
        expect(renamed_files).to be_empty
      end
    end
  end
end
