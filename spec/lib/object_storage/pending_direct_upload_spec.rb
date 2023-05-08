# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ObjectStorage::PendingDirectUpload, :clean_gitlab_redis_shared_state, feature_category: :shared do
  let(:location_identifier) { :artifacts }
  let(:path) { 'some/path/123' }

  describe '.prepare' do
    it 'creates a redis entry for the given location identifier and path' do
      freeze_time do
        described_class.prepare(location_identifier, path)

        ::Gitlab::Redis::SharedState.with do |redis|
          key = described_class.key(location_identifier, path)
          expect(redis.hget('pending_direct_uploads', key)).to eq(Time.current.utc.to_i.to_s)
        end
      end
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

      described_class.complete(location_identifier, path)

      expect(described_class.exists?(location_identifier, path)).to eq(false)
    end
  end

  describe '.key' do
    subject { described_class.key(location_identifier, path) }

    it { is_expected.to eq("#{location_identifier}:#{path}") }
  end
end
