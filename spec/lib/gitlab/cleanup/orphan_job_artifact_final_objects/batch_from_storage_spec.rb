# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cleanup::OrphanJobArtifactFinalObjects::BatchFromStorage, :orphan_final_artifacts_cleanup, :clean_gitlab_redis_shared_state, feature_category: :job_artifacts do
  describe '#orphan_objects' do
    before do
      Gitlab.config.artifacts.object_store.tap do |config|
        config[:remote_directory] = remote_directory
        config[:bucket_prefix] = bucket_prefix
      end
    end

    let(:batch) do
      described_class.new(
        fog_collection,
        bucket_prefix: bucket_prefix
      )
    end

    let(:fog_connection) do
      stub_object_storage_uploader(
        config: Gitlab.config.artifacts.object_store,
        uploader: JobArtifactUploader,
        direct_upload: true
      )
    end

    let(:remote_directory) { 'artifacts' }
    let(:bucket_prefix) { nil }
    let(:fog_collection) { fog_connection.directories.new(key: remote_directory).files.all }

    let!(:orphan_final_object_1) { create_fog_file }
    let!(:orphan_final_object_2) { create_fog_file }
    let!(:orphan_non_final_object) { create_fog_file(final: false) }

    let!(:object_with_job_artifact_record) do
      create_fog_file.tap do |file|
        create(:ci_job_artifact, file_final_path: path_without_bucket_prefix(file.key))
      end
    end

    let!(:object_with_pending_direct_upload) do
      create_fog_file.tap do |file|
        ObjectStorage::PendingDirectUpload.prepare(:artifacts, path_without_bucket_prefix(file.key))
      end
    end

    subject(:orphan_objects) { batch.orphan_objects }

    shared_examples_for 'returning orphan final job artifact objects' do
      it 'returns all orphan Fog files from the given Fog collection' do
        expect(orphan_objects).to contain_exactly(orphan_final_object_1, orphan_final_object_2)
      end
    end

    context 'when not configured to use bucket_prefix' do
      let(:remote_directory) { 'artifacts' }
      let(:bucket_prefix) { nil }

      it_behaves_like 'returning orphan final job artifact objects'
    end

    context 'when configured to use bucket_prefix' do
      let(:remote_directory) { 'main-bucket' }
      let(:bucket_prefix) { 'my/artifacts' }

      it_behaves_like 'returning orphan final job artifact objects'
    end
  end
end
