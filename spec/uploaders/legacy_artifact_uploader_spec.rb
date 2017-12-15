require 'rails_helper'

describe LegacyArtifactUploader do
  let(:store) { described_class::LOCAL_STORE }
  let(:job) { create(:ci_build, artifacts_file_store: store) }
  let(:uploader) { described_class.new(job, :legacy_artifacts_file) }
  let(:local_path) { Gitlab.config.artifacts.path }

  describe '.local_store_path' do
    subject { described_class.local_store_path }

    it "delegate to artifacts path" do
      expect(Gitlab.config.artifacts).to receive(:path)

      subject
    end
  end

  describe '.artifacts_upload_path' do
    subject { described_class.artifacts_upload_path }

    it { is_expected.to start_with(local_path) }
    it { is_expected.to end_with('tmp/uploads/') }
  end

  describe '#store_dir' do
    subject { uploader.store_dir }

    let(:path) { "#{job.created_at.utc.strftime('%Y_%m')}/#{job.project_id}/#{job.id}" }

    context 'when using local storage' do
      it { is_expected.to start_with(local_path) }
      it { is_expected.to end_with(path) }
    end

    context 'when using remote storage' do
      let(:store) { described_class::REMOTE_STORE }

      before do
        stub_artifacts_object_storage
      end

      it { is_expected.to eq(path) }
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

  describe '#filename' do
    # we need to use uploader, as this makes to use mounter
    # which initialises uploader.file object
    let(:uploader) { job.artifacts_file }

    subject { uploader.filename }

    it { is_expected.to be_nil }
  end

  context 'file is stored in valid path' do
    let(:file) do
      fixture_file_upload(
        Rails.root.join('spec/fixtures/ci_build_artifacts.zip'), 'application/zip')
    end

    before do
      uploader.store!(file)
    end

    subject { uploader.file.path }

    it { is_expected.to start_with(local_path) }
    it { is_expected.to include("/#{job.created_at.utc.strftime('%Y_%m')}/") }
    it { is_expected.to include("/#{job.project_id}/") }
    it { is_expected.to end_with("ci_build_artifacts.zip") }
  end
end
