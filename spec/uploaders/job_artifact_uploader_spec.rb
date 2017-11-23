require 'spec_helper'

describe JobArtifactUploader do
  set(:job_artifact) { create(:ci_job_artifact) }
  let(:uploader) { described_class.new(job_artifact, :file) }
  let(:path) { Gitlab.config.artifacts.path }

  describe '#store_dir' do
    subject { uploader.store_dir }

    it { is_expected.to start_with(path) }
    it { is_expected.not_to end_with("#{job_artifact.project_id}/#{job_artifact.created_at.utc.strftime('%Y_%m')}/#{job_artifact.id}") }
    it { is_expected.to match(/\h{2}\/\h{2}\/\h{64}\/\d{4}_\d{1,2}_\d{1,2}\/\d+\/\d+\z/) }
  end

  describe '#cache_dir' do
    subject { uploader.cache_dir }

    it { is_expected.to start_with(path) }
    it { is_expected.to end_with('/tmp/cache') }
  end

  describe '#work_dir' do
    subject { uploader.work_dir }

    it { is_expected.to start_with(path) }
    it { is_expected.to end_with('/tmp/work') }
  end

  context 'file is stored in valid path' do
    let(:file) do
      fixture_file_upload(Rails.root.join(
        'spec/fixtures/ci_build_artifacts.zip'), 'application/zip')
    end

    before do
      uploader.store!(file)
    end

    subject { uploader.file.path }

    it { is_expected.to start_with(path) }
    it { is_expected.to include("/#{job_artifact.created_at.utc.strftime('%Y_%m_%d')}/") }
    it { is_expected.to include("/#{job_artifact.project_id.to_s}/") }
    it { is_expected.to end_with("ci_build_artifacts.zip") }
  end
end
