# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ManifestImport::Metadata, :clean_gitlab_redis_shared_state do
  let(:user) { double(id: 1) }
  let(:repositories) do
    [
      { id: 'test1', url: 'http://demo.host/test1' },
      { id: 'test2', url: 'http://demo.host/test2' }
    ]
  end

  describe '#save' do
    let(:status) { described_class.new(user) }
    let(:hashtag_repositories_key) { 'manifest_import:metadata:user:{1}:repositories' }
    let(:hashtag_group_id_key) { 'manifest_import:metadata:user:{1}:group_id' }
    let(:repositories_key) { 'manifest_import:metadata:user:1:repositories' }
    let(:group_id_key) { 'manifest_import:metadata:user:1:group_id' }

    subject { status.save(repositories, 2) }

    it 'stores data in Redis with an expiry of EXPIRY_TIME' do
      subject

      Gitlab::Redis::SharedState.with do |redis|
        expect(redis.ttl(hashtag_repositories_key)).to be_within(5).of(described_class::EXPIRY_TIME)
        expect(redis.ttl(hashtag_group_id_key)).to be_within(5).of(described_class::EXPIRY_TIME)
        expect(redis.ttl(repositories_key)).to be_within(5).of(described_class::EXPIRY_TIME)
        expect(redis.ttl(group_id_key)).to be_within(5).of(described_class::EXPIRY_TIME)
      end
    end

    context 'with `manifest_import_use_hash_tagged_key`feature flag disabled' do
      before do
        stub_feature_flags(manifest_import_use_hash_tagged_key: false)
      end

      it 'only stores Redis String' do
        subject

        Gitlab::Redis::SharedState.with do |redis|
          expect(redis.ttl(hashtag_repositories_key)).to eq(-2)
          expect(redis.ttl(hashtag_group_id_key)).to eq(-2)
          expect(redis.ttl(repositories_key)).to be_within(5).of(described_class::EXPIRY_TIME)
          expect(redis.ttl(group_id_key)).to be_within(5).of(described_class::EXPIRY_TIME)
        end
      end
    end
  end

  describe '#repositories' do
    shared_examples 'read repositories' do
      it 'allows repositories to round-trip with symbol keys' do
        status = described_class.new(user)

        status.save(repositories, 2)

        expect(status.repositories).to eq(repositories)
      end

      it 'uses the fallback when there is nothing in Redis' do
        fallback = { manifest_import_repositories: repositories }
        status = described_class.new(user, fallback: fallback)

        expect(status.repositories).to eq(repositories)
      end
    end

    context 'with `manifest_import_use_hash_tagged_key` feature flag disabled' do
      before do
        stub_feature_flags(manifest_import_use_hash_tagged_key: false)
      end

      it_behaves_like 'read repositories'
    end

    it_behaves_like 'read repositories'
  end

  describe '#group_id' do
    shared_examples 'read group_id' do
      it 'returns the group ID as an integer' do
        status = described_class.new(user)

        status.save(repositories, 2)

        expect(status.group_id).to eq(2)
      end

      it 'uses the fallback when there is nothing in Redis' do
        fallback = { manifest_import_group_id: 3 }
        status = described_class.new(user, fallback: fallback)

        expect(status.group_id).to eq(3)
      end
    end

    context 'with feature flag disabled' do
      before do
        stub_feature_flags(manifest_import_use_hash_tagged_key: false)
      end

      it_behaves_like 'read group_id'
    end

    it_behaves_like 'read group_id'
  end
end
