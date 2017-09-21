require 'rails_helper'

describe ArtifactUploader do
  set(:job) { create(:ci_build) }
  let(:uploader) { described_class.new(job, :artifacts_file) }
  let(:path) { Gitlab.config.artifacts.path }

  describe '.local_artifacts_store' do
    subject { described_class.local_artifacts_store }

    it "delegate to artifacts path" do
      expect(Gitlab.config.artifacts).to receive(:path)

      subject
    end
  end

  describe '.artifacts_upload_path' do
    subject { described_class.artifacts_upload_path }

    it { is_expected.to start_with(path) }
    it { is_expected.to end_with('tmp/uploads/') }
  end

  describe '#store_dir' do
    subject { uploader.store_dir }

    it { is_expected.to start_with(path) }
    it { is_expected.to end_with("#{job.project_id}/#{job.created_at.utc.strftime('%Y_%m')}/#{job.id}") }
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

  describe '#filename' do
    # we need to use uploader, as this makes to use mounter
    # which initialises uploader.file object
    let(:uploader) { job.artifacts_file }

    subject { uploader.filename }

    it { is_expected.to be_nil }

    context 'with artifacts' do
      let(:job) { create(:ci_build, :artifacts) }

      it { is_expected.not_to be_nil }
    end
  end
end
