# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JobArtifactUploader do
  let(:store) { described_class::Store::LOCAL }
  let(:job_artifact) { create(:ci_job_artifact, file_store: store) }
  let(:uploader) { described_class.new(job_artifact, :file) }

  subject { uploader }

  it_behaves_like "builds correct paths",
    store_dir: %r[\h{2}/\h{2}/\h{64}/\d{4}_\d{1,2}_\d{1,2}/\d+/\d+\z],
    cache_dir: %r{artifacts/tmp/cache},
    work_dir: %r{artifacts/tmp/work}

  context "object store is REMOTE" do
    before do
      stub_artifacts_object_storage
    end

    include_context 'with storage', described_class::Store::REMOTE

    it_behaves_like "builds correct paths",
      store_dir: %r[\h{2}/\h{2}/\h{64}/\d{4}_\d{1,2}_\d{1,2}/\d+/\d+\z]

    describe '#cdn_enabled_url' do
      it 'returns URL and false' do
        result = uploader.cdn_enabled_url('127.0.0.1')

        expect(result.used_cdn).to be false
      end
    end
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

  describe '#dynamic_segment' do
    let(:uploaded_content) { File.binread(Rails.root + 'spec/fixtures/ci_build_artifacts.zip') }
    let(:model) { uploader.model }

    shared_examples_for 'Read file from legacy path' do
      it 'store_path returns the legacy path' do
        expect(model.file.store_path).to eq(File.join(model.created_at.utc.strftime('%Y_%m'), model.project_id.to_s, model.job_id.to_s, 'ci_build_artifacts.zip'))
      end

      it 'has exactly the same content' do
        expect(::File.binread(model.file.path)).to eq(uploaded_content)
      end
    end

    shared_examples_for 'Read file from hashed path' do
      it 'store_path returns hashed path' do
        expect(model.file.store_path).to eq(File.join(disk_hash[0..1], disk_hash[2..3], disk_hash, creation_date, model.job_id.to_s, model.id.to_s, 'ci_build_artifacts.zip'))
      end

      it 'has exactly the same content' do
        expect(::File.binread(model.file.path)).to eq(uploaded_content)
      end
    end

    context 'when a job artifact is stored in legacy_path' do
      let(:job_artifact) { create(:ci_job_artifact, :legacy_archive) }

      it_behaves_like 'Read file from legacy path'
    end

    context 'when the artifact file is stored in hashed_path' do
      let(:job_artifact) { create(:ci_job_artifact, :archive) }
      let(:disk_hash) { Digest::SHA2.hexdigest(model.project_id.to_s) }
      let(:creation_date) { model.created_at.utc.strftime('%Y_%m_%d') }

      it_behaves_like 'Read file from hashed path'

      context 'when file_location column is empty' do
        before do
          job_artifact.update_column(:file_location, nil)
        end

        it_behaves_like 'Read file from hashed path'
      end
    end
  end

  describe "#migrate!" do
    before do
      uploader.store!(fixture_file_upload('spec/fixtures/trace/sample_trace'))
      stub_artifacts_object_storage
    end

    it_behaves_like "migrates", to_store: described_class::Store::REMOTE
    it_behaves_like "migrates", from_store: described_class::Store::REMOTE, to_store: described_class::Store::LOCAL

    # CI job artifacts usually are shown as text/plain, but they contain
    # escape characters so MIME detectors usually fail to determine what
    # the Content-Type is.
    it 'does not set Content-Type' do
      expect(uploader.file.content_type).to be_blank
    end
  end
end
