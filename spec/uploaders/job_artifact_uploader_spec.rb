require 'spec_helper'

describe JobArtifactUploader do
  let(:store) { described_class::Store::LOCAL }
  let(:job_artifact) { create(:ci_job_artifact, file_store: store) }
  let(:uploader) { described_class.new(job_artifact, :file) }

  subject { uploader }

  it_behaves_like "builds correct paths",
                  store_dir: %r[\h{2}/\h{2}/\h{64}/\d{4}_\d{1,2}_\d{1,2}/\d+/\d+\z],
                  cache_dir: %r[artifacts/tmp/cache],
                  work_dir: %r[artifacts/tmp/work]

  context "object store is REMOTE" do
    before do
      stub_artifacts_object_storage
    end

    include_context 'with storage', described_class::Store::REMOTE

    it_behaves_like "builds correct paths",
                    store_dir: %r[\h{2}/\h{2}/\h{64}/\d{4}_\d{1,2}_\d{1,2}/\d+/\d+\z]
  end

  context 'file is stored in valid local_path' do
    let(:file) do
      fixture_file_upload('spec/fixtures/ci_build_artifacts.zip', 'application/zip')
    end

    before do
      uploader.store!(file)
    end

    subject { uploader.file.path }

    it { is_expected.to start_with("#{uploader.root}/#{uploader.class.base_dir}") }
    it { is_expected.to include("/#{job_artifact.created_at.utc.strftime('%Y_%m_%d')}/") }
    it { is_expected.to include("/#{job_artifact.job_id}/#{job_artifact.id}/") }
    it { is_expected.to end_with("ci_build_artifacts.zip") }
  end

  describe "#migrate!" do
    before do
      uploader.store!(fixture_file_upload('spec/fixtures/trace/sample_trace'))
      stub_artifacts_object_storage
    end

    it_behaves_like "migrates", to_store: described_class::Store::REMOTE
    it_behaves_like "migrates", from_store: described_class::Store::REMOTE, to_store: described_class::Store::LOCAL
  end
end
