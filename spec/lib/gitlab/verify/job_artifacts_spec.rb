require 'spec_helper'

describe Gitlab::Verify::JobArtifacts do
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
      expect(failure).to be_a(Errno::ENOENT)
      expect(failure.to_s).to include(artifact.file.path)
    end

    it 'fails artifacts with a mismatched checksum' do
      File.truncate(artifact.file.path, 0)

      expect(failures.keys).to contain_exactly(artifact)
      expect(failure.to_s).to include('Checksum mismatch')
    end
  end
end
