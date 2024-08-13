# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ObjectStorage::DeleteStaleDirectUploadsWorker, :direct_uploads, :clean_gitlab_redis_shared_state, feature_category: :shared do
  let(:worker) { described_class.new }

  describe '#perform' do
    it 'executes a service' do
      expect_next_instance_of(ObjectStorage::DeleteStaleDirectUploadsService) do |instance|
        expect(instance).to receive(:execute).and_call_original
      end

      worker.perform
    end
  end

  context 'when using an idempotent worker', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/444869' do
    it_behaves_like 'an idempotent worker' do
      let(:location_identifier) { JobArtifactUploader.storage_location_identifier }
      let(:fog_connection) { stub_artifacts_object_storage(JobArtifactUploader, direct_upload: true) }

      let(:stale_remote_path) { 'stale/path/123' }
      let!(:stale_object) do
        fog_connection.directories
          .new(key: location_identifier.to_s)
          .files
          .create( # rubocop:disable Rails/SaveBang
            key: stale_remote_path,
            body: 'something'
          )
      end

      let(:non_stale_remote_path) { 'nonstale/path/123' }
      let!(:non_stale_object) do
        fog_connection.directories
          .new(key: location_identifier.to_s)
          .files
          .create( # rubocop:disable Rails/SaveBang
            key: non_stale_remote_path,
            body: 'something'
          )
      end

      it 'only deletes stale entries', :aggregate_failures do
        prepare_pending_direct_upload(stale_remote_path, 4.hours.ago)
        prepare_pending_direct_upload(non_stale_remote_path, 3.minutes.ago)

        subject

        expect_not_to_have_pending_direct_upload(stale_remote_path)
        expect_pending_uploaded_object_not_to_exist(stale_remote_path)

        expect_to_have_pending_direct_upload(non_stale_remote_path)
        expect_pending_uploaded_object_to_exist(non_stale_remote_path)
      end
    end
  end
end
