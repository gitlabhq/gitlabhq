# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ObjectStorage::PendingDirectUpload, :direct_uploads, :clean_gitlab_redis_shared_state, feature_category: :shared do
  let(:location_identifier) { :artifacts }
  let(:path) { 'some/path/123' }

  describe '.prepare' do
    it 'creates a redis entry for the given location identifier and path' do
      redis_key = described_class.redis_key(location_identifier, path)

      expect_to_log(:prepared, redis_key)

      freeze_time do
        described_class.prepare(location_identifier, path)

        ::Gitlab::Redis::SharedState.with do |redis|
          expect(redis.hget('pending_direct_uploads', redis_key)).to eq(Time.current.utc.to_i.to_s)
        end
      end
    end
  end

  describe '.count' do
    subject { described_class.count }

    before do
      described_class.prepare(:artifacts, 'some/path')
      described_class.prepare(:uploads, 'some/other/path')
      described_class.prepare(:artifacts, 'some/new/path')
    end

    it { is_expected.to eq(3) }
  end

  describe '.with_pending_only' do
    let(:path_1) { 'some/path/123' }
    let(:path_2) { 'some/path/456' }
    let(:path_3) { 'some/path/789' }
    let(:paths) { [path_1, path_2, path_3] }

    subject(:result) { described_class.with_pending_only(location_identifier, paths) }

    before do
      described_class.prepare(location_identifier, path_1)
      described_class.prepare(:uploads, path_2)
      described_class.prepare(location_identifier, path_3)
    end

    it 'selects and returns the paths with a matching redis entry under the location identifier' do
      expect(result).to eq([path_1, path_3])
    end
  end

  describe '.exists?' do
    let(:path) { 'some/path/123' }

    subject { described_class.exists?(given_identifier, given_path) }

    before do
      described_class.prepare(location_identifier, path)
    end

    context 'when there is a matching redis entry for the given path under the location identifier' do
      let(:given_identifier) { location_identifier }
      let(:given_path) { path }

      it { is_expected.to eq(true) }
    end

    context 'when there is a matching redis entry for the given path under a different location identifier' do
      let(:given_identifier) { :uploads }
      let(:given_path) { path }

      it { is_expected.to eq(false) }
    end

    context 'when there is no matching redis entry for the given path under the location identifier' do
      let(:given_identifier) { location_identifier }
      let(:given_path) { 'wrong/path/123' }

      it { is_expected.to eq(false) }
    end
  end

  describe '.complete' do
    it 'deletes the redis entry for the given path' do
      described_class.prepare(location_identifier, path)

      expect(described_class.exists?(location_identifier, path)).to eq(true)

      redis_key = described_class.redis_key(location_identifier, path)

      expect_to_log(:completed, redis_key)

      described_class.complete(location_identifier, path)

      expect(described_class.exists?(location_identifier, path)).to eq(false)
    end
  end

  describe '.redis_key' do
    subject { described_class.redis_key(location_identifier, path) }

    it { is_expected.to eq("#{location_identifier}:#{path}") }
  end

  describe '.each' do
    before do
      described_class.prepare(:artifacts, 'some/path')
      described_class.prepare(:uploads, 'some/other/path')
      described_class.prepare(:artifacts, 'some/new/path')
    end

    it 'yields each pending direct upload object' do
      expect { |b| described_class.each(&b) }.to yield_control.exactly(3).times
    end
  end

  describe '#stale?' do
    let(:pending_direct_upload) do
      described_class.new(
        redis_key: 'artifacts:some/path',
        storage_location_identifier: 'artifacts',
        object_storage_path: 'some/path',
        timestamp: timestamp
      )
    end

    subject { pending_direct_upload.stale? }

    context 'when timestamp is older than 3 hours ago' do
      let(:timestamp) { 4.hours.ago.utc.to_i }

      it { is_expected.to eq(true) }
    end

    context 'when timestamp is not older than 3 hours ago' do
      let(:timestamp) { 2.hours.ago.utc.to_i }

      it { is_expected.to eq(false) }
    end
  end

  describe '#delete' do
    let(:object_storage_path) { 'some/path' }
    let(:pending_direct_upload) do
      described_class.new(
        redis_key: 'artifacts:some/path',
        storage_location_identifier: location_identifier,
        object_storage_path: object_storage_path,
        timestamp: 4.hours.ago
      )
    end

    let(:location_identifier) { JobArtifactUploader.storage_location_identifier }
    let(:fog_connection) { stub_artifacts_object_storage(JobArtifactUploader, direct_upload: true) }

    before do
      fog_connection.directories
        .new(key: location_identifier.to_s)
        .files
        .create( # rubocop:disable Rails/SaveBang
          key: object_storage_path,
          body: 'something'
        )

      prepare_pending_direct_upload(object_storage_path, 4.hours.ago)
    end

    it 'deletes the object from storage and also the redis entry',
      quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/450627' do
      redis_key = described_class.redis_key(location_identifier, object_storage_path)

      expect_to_log(:deleted, redis_key)

      expect { pending_direct_upload.delete }.to change { total_pending_direct_uploads }.by(-1)

      expect_not_to_have_pending_direct_upload(object_storage_path)
      expect_pending_uploaded_object_not_to_exist(object_storage_path)
    end
  end

  def expect_to_log(event, redis_key)
    expect(Gitlab::AppLogger).to receive(:info).with(
      message: "Pending direct upload #{event}",
      redis_key: redis_key
    )
  end
end
