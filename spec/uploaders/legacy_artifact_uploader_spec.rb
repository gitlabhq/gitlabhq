require 'rails_helper'

describe LegacyArtifactUploader do
  let(:store) { described_class::Store::LOCAL }
  let(:job) { create(:ci_build, artifacts_file_store: store) }
  let(:uploader) { described_class.new(job, :legacy_artifacts_file) }
  let(:local_path) { described_class.root }

  subject { uploader }

  # TODO: move to Workhorse::UploadPath
  describe '.workhorse_upload_path' do
    subject { described_class.workhorse_upload_path }

    it { is_expected.to start_with(local_path) }
    it { is_expected.to end_with('tmp/uploads') }
  end

  it_behaves_like "builds correct paths",
                  store_dir: %r[\d{4}_\d{1,2}/\d+/\d+\z],
                  cache_dir: %r[artifacts/tmp/cache],
                  work_dir: %r[artifacts/tmp/work]

  context 'object store is remote' do
    before do
      stub_artifacts_object_storage
    end

    include_context 'with storage', described_class::Store::REMOTE

    it_behaves_like "builds correct paths",
                    store_dir: %r[\d{4}_\d{1,2}/\d+/\d+\z]
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

    it { is_expected.to start_with("#{uploader.root}") }
    it { is_expected.to include("/#{job.created_at.utc.strftime('%Y_%m')}/") }
    it { is_expected.to include("/#{job.project_id}/") }
    it { is_expected.to end_with("ci_build_artifacts.zip") }
  end
end
