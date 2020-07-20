# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Verify::JobArtifacts do
  include GitlabVerifyHelpers

  it_behaves_like 'Gitlab::Verify::BatchVerifier subclass' do
    let!(:objects) { create_list(:ci_job_artifact, 3, :archive) }
  end

  describe '#run_batches' do
    let(:failures) { collect_failures }
    let(:failure) { failures[artifact] }

    let!(:artifact) { create(:ci_job_artifact, :archive, :correct_checksum) }

    it 'passes artifacts with the correct file' do
      expect(failures).to eq({})
    end

    it 'fails artifacts with a missing file' do
      FileUtils.rm_f(artifact.file.path)

      expect(failures.keys).to contain_exactly(artifact)
      expect(failure).to include('No such file or directory')
      expect(failure).to include(artifact.file.path)
    end

    it 'fails artifacts with a mismatched checksum' do
      File.truncate(artifact.file.path, 0)

      expect(failures.keys).to contain_exactly(artifact)
      expect(failure).to include('Checksum mismatch')
    end

    context 'with remote files' do
      let(:file) { double(:file) }

      before do
        stub_artifacts_object_storage
        artifact.update!(file_store: ObjectStorage::Store::REMOTE)
        expect(CarrierWave::Storage::Fog::File).to receive(:new).and_return(file)
      end

      it 'passes artifacts in object storage that exist' do
        expect(file).to receive(:exists?).and_return(true)

        expect(failures).to eq({})
      end

      it 'fails artifacts in object storage that do not exist' do
        expect(file).to receive(:exists?).and_return(false)

        expect(failures.keys).to contain_exactly(artifact)
        expect(failure).to include('Remote object does not exist')
      end
    end
  end
end
