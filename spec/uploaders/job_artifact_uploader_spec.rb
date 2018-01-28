require 'spec_helper'

describe JobArtifactUploader do
  let(:job_artifact) { create(:ci_job_artifact) }
  let(:uploader) { described_class.new(job_artifact, :file) }
  let(:local_path) { Gitlab.config.artifacts.path }

  describe '#store_dir' do
    subject { uploader.store_dir }

    let(:path) { "#{job_artifact.created_at.utc.strftime('%Y_%m_%d')}/#{job_artifact.job_id}/#{job_artifact.id}" }

    context 'when using local storage' do
      it { is_expected.to start_with(local_path) }
      it { is_expected.to match(/\h{2}\/\h{2}\/\h{64}\/\d{4}_\d{1,2}_\d{1,2}\/\d+\/\d+\z/) }
      it { is_expected.to end_with(path) }
    end
  end

  describe '#cache_dir' do
    subject { uploader.cache_dir }

    it { is_expected.to start_with(local_path) }
    it { is_expected.to end_with('/tmp/cache') }
  end

  describe '#work_dir' do
    subject { uploader.work_dir }

    it { is_expected.to start_with(local_path) }
    it { is_expected.to end_with('/tmp/work') }
  end

  context 'file is stored in valid local_path' do
    let(:file) do
      fixture_file_upload(
        Rails.root.join('spec/fixtures/ci_build_artifacts.zip'), 'application/zip')
    end

    before do
      uploader.store!(file)
    end

    subject { uploader.file.path }

    it { is_expected.to start_with(local_path) }
    it { is_expected.to include("/#{job_artifact.created_at.utc.strftime('%Y_%m_%d')}/") }
    it { is_expected.to include("/#{job_artifact.job_id}/#{job_artifact.id}/") }
    it { is_expected.to end_with("ci_build_artifacts.zip") }
  end
end
