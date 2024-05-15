# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ObjectStorage::DeleteStaleDirectUploadsService, :direct_uploads, :clean_gitlab_redis_shared_state, feature_category: :shared do
  let(:service) { described_class.new }

  describe '#execute', :aggregate_failures do
    subject(:execute_result) { service.execute }

    let(:location_identifier) { JobArtifactUploader.storage_location_identifier }
    let(:fog_connection) { stub_artifacts_object_storage(JobArtifactUploader, direct_upload: true) }

    let(:stale_path_1) { 'stale/path/123' }
    let!(:stale_object_1) do
      fog_connection.directories
        .new(key: location_identifier.to_s)
        .files
        .create( # rubocop:disable Rails/SaveBang
          key: stale_path_1,
          body: 'something'
        )
    end

    let(:stale_path_2) { 'stale/path/456' }
    let!(:stale_object_2) do
      fog_connection.directories
        .new(key: location_identifier.to_s)
        .files
        .create( # rubocop:disable Rails/SaveBang
          key: stale_path_2,
          body: 'something'
        )
    end

    let(:non_stale_path) { 'nonstale/path/123' }
    let!(:non_stale_object) do
      fog_connection.directories
        .new(key: location_identifier.to_s)
        .files
        .create( # rubocop:disable Rails/SaveBang
          key: non_stale_path,
          body: 'something'
        )
    end

    it 'only deletes stale entries', :aggregate_failures,
      quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/461534' do
      prepare_pending_direct_upload(stale_path_1, 5.hours.ago)
      prepare_pending_direct_upload(stale_path_2, 4.hours.ago)
      prepare_pending_direct_upload(non_stale_path, 3.minutes.ago)

      expect(execute_result).to eq(
        status: :success,
        total_pending_entries: 3,
        total_deleted_stale_entries: 2,
        execution_timeout: false
      )

      expect_not_to_have_pending_direct_upload(stale_path_1)
      expect_pending_uploaded_object_not_to_exist(stale_path_1)

      expect_not_to_have_pending_direct_upload(stale_path_2)
      expect_pending_uploaded_object_not_to_exist(stale_path_2)

      expect_to_have_pending_direct_upload(non_stale_path)
      expect_pending_uploaded_object_to_exist(non_stale_path)
    end

    context 'when a stale entry does not have a matching object in the storage' do
      it 'does not fail and still remove the stale entry',
        quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/444747' do
        stale_no_object_path = 'some/other/path'
        prepare_pending_direct_upload(stale_path_1, 5.hours.ago)
        prepare_pending_direct_upload(stale_no_object_path, 5.hours.ago)

        expect(execute_result[:status]).to eq(:success)

        expect_not_to_have_pending_direct_upload(stale_path_1)
        expect_pending_uploaded_object_not_to_exist(stale_path_1)

        expect_not_to_have_pending_direct_upload(stale_no_object_path)
      end
    end

    context 'when timeout happens' do
      before do
        stub_const("#{described_class}::MAX_EXEC_DURATION", 0.seconds)

        prepare_pending_direct_upload(stale_path_1, 5.hours.ago)
        prepare_pending_direct_upload(stale_path_2, 4.hours.ago)
      end

      it 'completes the current iteration and reports information about total entries',
        quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/444748' do
        expect(execute_result).to eq(
          status: :success,
          total_pending_entries: 2,
          total_deleted_stale_entries: 1,
          execution_timeout: true
        )

        expect_not_to_have_pending_direct_upload(stale_path_1)
        expect_pending_uploaded_object_not_to_exist(stale_path_1)

        expect_to_have_pending_direct_upload(stale_path_2)
        expect_pending_uploaded_object_to_exist(stale_path_2)
      end
    end
  end
end
