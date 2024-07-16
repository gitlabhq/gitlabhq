# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cleanup::OrphanJobArtifactFinalObjects::BatchFromList, :orphan_final_artifacts_cleanup, :clean_gitlab_redis_shared_state, feature_category: :job_artifacts do
  describe '#orphan_objects' do
    before do
      Gitlab.config.artifacts.object_store.tap do |config|
        config[:remote_directory] = remote_directory
        config[:bucket_prefix] = bucket_prefix
      end

      allow(Gitlab::AppLogger).to receive(:info)
    end

    let(:batch) { described_class.new(entries) }

    let(:fog_connection) do
      stub_object_storage_uploader(
        config: Gitlab.config.artifacts.object_store,
        uploader: JobArtifactUploader,
        direct_upload: true
      )
    end

    let(:remote_directory) { 'artifacts' }
    let(:bucket_prefix) { nil }

    let(:entries) do
      [
        [orphan_final_object_1.key, orphan_final_object_1.content_length].join(','),
        [orphan_final_object_2.key, orphan_final_object_2.content_length].join(','),
        [non_existent_object.key, non_existent_object.content_length].join(','),
        [object_with_job_artifact_record.key, object_with_job_artifact_record.content_length].join(',')
      ]
    end

    let!(:orphan_final_object_1) { create_fog_file }
    let!(:orphan_final_object_2) { create_fog_file }
    let!(:non_existent_object) { create_fog_file.tap(&:destroy) }

    let!(:object_with_job_artifact_record) do
      create_fog_file.tap do |file|
        create(:ci_job_artifact, file_final_path: path_without_bucket_prefix(file.key))
      end
    end

    subject(:orphan_objects) { batch.orphan_objects }

    shared_examples_for 'returning orphan final job artifact objects' do
      context 'when the configured object storage provider is google' do
        before do
          allow(Gitlab.config.artifacts.object_store.connection).to receive(:provider).and_return('Google')

          # Given Fog doesn't have mock implementation for Google provider, we can only
          # check that the metadata method is properly called with the correct parameters.
          allow(batch).to receive_message_chain(:artifacts_directory, :files, :metadata)
            .with(orphan_final_object_1.key).and_return(orphan_final_object_1)

          allow(batch).to receive_message_chain(:artifacts_directory, :files, :metadata)
            .with(orphan_final_object_2.key).and_return(orphan_final_object_2)

          allow(batch).to receive_message_chain(:artifacts_directory, :files, :metadata)
            .with(non_existent_object.key).and_return(nil)

          allow(batch).to receive_message_chain(:artifacts_directory, :files, :metadata)
            .with(object_with_job_artifact_record.key).and_return(object_with_job_artifact_record)
        end

        it 'only returns existing orphan Fog files from the given CSV entries' do
          expect(orphan_objects).to contain_exactly(orphan_final_object_1, orphan_final_object_2)

          expect_skipping_non_existent_object_log_message(non_existent_object)
          expect_skipping_object_with_job_artifact_record_log_message(object_with_job_artifact_record)
        end
      end

      context 'when the configured object storage provider is not google' do
        it 'returns all orphan Fog files from the given CSV entries' do
          expect(orphan_objects).to contain_exactly(orphan_final_object_1, orphan_final_object_2, non_existent_object)

          expect_skipping_object_with_job_artifact_record_log_message(object_with_job_artifact_record)
        end
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
