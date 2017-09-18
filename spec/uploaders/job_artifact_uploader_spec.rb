require 'spec_helper'

describe JobArtifactUploader do
  set(:job_artifact) { create(:ci_job_artifact) }
  let(:job) { job_artifact.job }
  let(:uploader) { described_class.new(job_artifact, :file) }

  describe '#store_dir' do
    subject { uploader.store_dir }

    it { is_expected.to start_with(Gitlab.config.artifacts.path) }
    it { is_expected.not_to end_with("#{job.project_id}/#{job.created_at.utc.strftime('%Y_%m')}/#{job.id}") }
    it { is_expected.to match(/\h{2}\/\h{2}\/\h{64}\/\d{4}_\d{1,2}_\d{1,2}\/\d+\/\d+\z/) }
  end
end
