# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::DuplicateJobs::Cookie,
  :clean_gitlab_redis_queues_metadata, feature_category: :scalability do
  let(:key) { 'foo' }

  describe '.read' do
    before do
      with_redis { |r| r.set(key, cookie.to_msgpack, ex: 5.minutes) }
    end

    subject(:read) { described_class.read(key) }

    context 'with current schema and converter' do
      using RSpec::Parameterized::TableSyntax

      where(:cookie, :want) do
        [
          [
            { 'jid' => '123', 'offsets' => {}, 'wal_locations' => {}, 'existing_wal_locations' => {} },
            { 'jid' => '123', 'offsets' => {}, 'wal_locations' => {}, 'existing_wal_locations' => {} }
          ],
          [
            # empty array is converted to hash
            { 'jid' => '123', 'offsets' => [], 'wal_locations' => [], 'existing_wal_locations' => [] },
            { 'jid' => '123', 'offsets' => {}, 'wal_locations' => {}, 'existing_wal_locations' => {} }
          ],
          [
            # non-empty arrays are kept
            { 'jid' => '123', 'offsets' => ['a'], 'wal_locations' => { 'a' => 1 }, 'existing_wal_locations' => {} },
            { 'jid' => '123', 'offsets' => ['a'], 'wal_locations' => { 'a' => 1 }, 'existing_wal_locations' => {} }
          ],
          [
            # types outside converter is untouched
            { 'jid' => 123, 'offsets' => {}, 'wal_locations' => {}, 'existing_wal_locations' => {} },
            { 'jid' => 123, 'offsets' => {}, 'wal_locations' => {}, 'existing_wal_locations' => {} }
          ],
          [
            # keys outside schema are untouched
            { 'foo' => {} },
            { 'foo' => {} }
          ]
        ]
      end

      with_them do
        it 'reads from redis, validates and converts when needed' do
          expect(read).to eq(want)
        end
      end
    end
  end

  describe '#write' do
    let(:payload) do
      {
        jid: 123,
        existing_wal_locations: {}
      }
    end

    let(:key) { 'foo' }
    let(:ttl) { 5.minutes }

    subject(:write) { described_class.new(**payload).write(key, ttl) }

    it 'writes to redis' do
      expected = payload.merge({ offsets: {}, wal_locations: {} })
      Gitlab::Redis::QueuesMetadata.with do |redis|
        expect(redis).to receive(:set).with(key, expected.to_msgpack, nx: true, ex: ttl)
      end

      write
    end
  end

  describe '.delete!' do
    subject(:delete) { described_class.delete!(key) }

    it 'sends del command to redis' do
      Gitlab::Redis::QueuesMetadata.with do |redis|
        expect(redis).to receive(:del).with(key)
      end

      delete
    end
  end

  describe '.update_wal_locations!' do
    subject(:update_wal_locations!) { described_class.update_wal_locations!(cookie_key, argv) }

    let(:cookie_key) { "#{Gitlab::Redis::Queues::SIDEKIQ_NAMESPACE}:#{idempotency_key}:cookie:v2" }
    let(:cookie) { described_class.read(cookie_key) }
    let(:idempotency_key) { "foobar" }
    let(:argv) { ['c1', 1, 'loc1', 'c2', 2, 'loc2', 'c3', 3, 'loc3'] }

    it 'does not create the key' do
      update_wal_locations!

      expect(with_redis { |r| r.get(cookie_key) }).to be_nil
    end

    context 'when the key exists' do
      let(:existing_cookie) { { 'offsets' => {}, 'wal_locations' => {}, 'existing_wal_locations' => {} } }
      let(:expected_ttl) { 123 }

      before do
        with_redis { |r| r.set(cookie_key, existing_cookie.to_msgpack, ex: expected_ttl) }
      end

      it 'updates all connections' do
        update_wal_locations!

        expect(cookie['wal_locations']).to eq({ 'c1' => 'loc1', 'c2' => 'loc2', 'c3' => 'loc3' })
        expect(cookie['offsets']).to eq({ 'c1' => 1, 'c2' => 2, 'c3' => 3 })
        expect(cookie['existing_wal_locations']).to eq({})
      end

      it 'preserves the ttl' do
        update_wal_locations!

        expect(redis_ttl(cookie_key)).to be_within(1).of(expected_ttl)
      end

      it 'does not try to set an invalid ttl at the end of expiry' do
        with_redis { |r| r.expire(cookie_key, 1) }

        sleep 0.5 # sleep 500ms to redis would round the remaining ttl to 0

        expect { update_wal_locations! }.not_to raise_error
      end

      context 'and low offsets' do
        let(:existing_cookie) do
          {
            'offsets' => { 'c1' => 0, 'c2' => 2 },
            'wal_locations' => { 'c1' => 'loc1old', 'c2' => 'loc2old' },
            'existing_wal_locations' => {}
          }
        end

        it 'updates only some connections' do
          update_wal_locations!

          expect(cookie['wal_locations']).to eq({ 'c1' => 'loc1', 'c2' => 'loc2old', 'c3' => 'loc3' })
          expect(cookie['offsets']).to eq({ 'c1' => 1, 'c2' => 2, 'c3' => 3 })
          expect(cookie['existing_wal_locations']).to eq({})
        end
      end

      context 'when a WAL location is nil with existing offsets' do
        let(:existing_cookie) do
          {
            'offsets' => { 'main' => 8, 'ci' => 5 },
            'wal_locations' => { 'main' => 'loc1old', 'ci' => 'loc2old' },
            'existing_wal_locations' => {}
          }
        end

        let(:argv) { ['main', 9, 'loc1', 'ci', '', 'loc2'] }

        it 'only updates the main connection' do
          update_wal_locations!

          expect(cookie['wal_locations']).to eq({ 'main' => 'loc1', 'ci' => 'loc2old' })
          expect(cookie['offsets']).to eq({ 'main' => 9, 'ci' => 5 })
          expect(cookie['existing_wal_locations']).to eq({})
        end
      end
    end
  end

  def with_redis(&block)
    Gitlab::Redis::QueuesMetadata.with(&block)
  end

  def redis_ttl(key)
    with_redis { |redis| redis.ttl(key) }
  end
end
