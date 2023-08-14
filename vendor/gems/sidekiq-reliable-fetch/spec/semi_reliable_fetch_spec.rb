require 'spec_helper'
require 'fetch_shared_examples'
require 'sidekiq/base_reliable_fetch'
require 'sidekiq/semi_reliable_fetch'

describe Sidekiq::SemiReliableFetch do
  include_examples 'a Sidekiq fetcher'

  describe '#retrieve_work' do
    let(:queues) { ['stuff_to_do'] }
    let(:options) { { queues: queues } }
    let(:fetcher) { described_class.new(options) }

    context 'namespace config' do
      let(:options) { { queues: queues, namespace: 'namespaced' } }

      before do
        Sidekiq.redis do |conn|
          conn.rpush('queue:stuff_to_do', 'msg1')
          conn.rpush('namespaced:queue:stuff_to_do', 'msg2')
        end
      end

      it 'runs brpop on both namespaced and non-namespaced' do
        jobs = (1..2).map { fetcher.retrieve_work&.job }

        expect(jobs).to match_array(['msg1', 'msg2'])
      end
    end

    context 'alternative_store config' do
      let(:store) { Sidekiq::RedisConnection.create(url: REDIS_URL, size: 10) }
      let(:options) { { queues: queues, alternative_store: store } }

      it 'connects using alternative store' do
        Sidekiq.redis do |connection|
          expect(connection).not_to receive(:brpop)
        end

        store.with do |connection|
          expect(connection).to receive(:brpop).with("queue:stuff_to_do", { timeout: 2 }).once.and_call_original
        end

        fetcher.retrieve_work
      end
    end

    context 'timeout config' do
      before do
        stub_env('SIDEKIQ_SEMI_RELIABLE_FETCH_TIMEOUT', timeout)
      end

      context 'when the timeout is not configured' do
        let(:timeout) { nil }

        it 'brpops with the default timeout timeout' do
          Sidekiq.redis do |connection|
            expect(connection).to receive(:brpop).with("queue:stuff_to_do", { timeout: 2 }).once.and_call_original

            fetcher.retrieve_work
          end
        end
      end

      context 'when the timeout is set in the env' do
        let(:timeout) { '5' }

        it 'brpops with the default timeout timeout' do
          Sidekiq.redis do |connection|
            expect(connection).to receive(:brpop).with("queue:stuff_to_do", { timeout: 5 }).once.and_call_original

            fetcher.retrieve_work
          end
        end
      end
    end
  end
end
