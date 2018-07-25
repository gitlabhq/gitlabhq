require 'spec_helper'

describe ReactiveCaching, :use_clean_rails_memory_store_caching do
  include ExclusiveLeaseHelpers
  include ReactiveCachingHelpers

  class CacheTest
    include ReactiveCaching

    self.reactive_cache_key = ->(thing) { ["foo", thing.id] }

    self.reactive_cache_lifetime = 5.minutes
    self.reactive_cache_refresh_interval = 15.seconds

    attr_reader :id

    def initialize(id, &blk)
      @id = id
      @calculator = blk
    end

    def calculate_reactive_cache
      @calculator.call
    end

    def result
      with_reactive_cache do |data|
        data / 2
      end
    end
  end

  let(:calculation) { -> { 2 + 2 } }
  let(:cache_key) { "foo:666" }
  let(:instance) { CacheTest.new(666, &calculation) }

  describe '#with_reactive_cache' do
    before do
      stub_reactive_cache
    end

    subject(:go!) { instance.result }

    context 'when cache is empty' do
      it { is_expected.to be_nil }

      it 'enqueues a background worker to bootstrap the cache' do
        expect(ReactiveCachingWorker).to receive(:perform_async).with(CacheTest, 666)

        go!
      end

      it 'updates the cache lifespan' do
        expect(reactive_cache_alive?(instance)).to be_falsy

        go!

        expect(reactive_cache_alive?(instance)).to be_truthy
      end
    end

    context 'when the cache is full' do
      before do
        stub_reactive_cache(instance, 4)
      end

      it { is_expected.to eq(2) }

      it 'does not enqueue a background worker' do
        expect(ReactiveCachingWorker).not_to receive(:perform_async)

        go!
      end

      it 'updates the cache lifespan' do
        expect(Rails.cache).to receive(:write).with(alive_reactive_cache_key(instance), true, expires_in: anything)

        go!
      end

      context 'and expired' do
        before do
          invalidate_reactive_cache(instance)
        end

        it { is_expected.to be_nil }
      end
    end
  end

  describe '#clear_reactive_cache!' do
    before do
      stub_reactive_cache(instance, 4)
      instance.clear_reactive_cache!
    end

    it { expect(instance.result).to be_nil }
    it { expect(reactive_cache_alive?(instance)).to be_falsy }
  end

  describe '#exclusively_update_reactive_cache!' do
    subject(:go!) { instance.exclusively_update_reactive_cache! }

    context 'when the lease is free and lifetime is not exceeded' do
      before do
        stub_reactive_cache(instance, "preexisting")
      end

      it 'takes and releases the lease' do
        expect_to_obtain_exclusive_lease(cache_key, 'uuid')
        expect_to_cancel_exclusive_lease(cache_key, 'uuid')

        go!
      end

      it 'caches the result of #calculate_reactive_cache' do
        go!

        expect(read_reactive_cache(instance)).to eq(calculation.call)
      end

      it "enqueues a repeat worker" do
        expect_reactive_cache_update_queued(instance)

        go!
      end

      it "calls a reactive_cache_updated only once if content did not change on subsequent update" do
        expect(instance).to receive(:calculate_reactive_cache).twice
        expect(instance).to receive(:reactive_cache_updated).once

        2.times { instance.exclusively_update_reactive_cache! }
      end

      context 'and #calculate_reactive_cache raises an exception' do
        before do
          stub_reactive_cache(instance, "preexisting")
        end

        let(:calculation) { -> { raise "foo"} }

        it 'leaves the cache untouched' do
          expect { go! }.to raise_error("foo")
          expect(read_reactive_cache(instance)).to eq("preexisting")
        end

        it 'enqueues a repeat worker' do
          expect_reactive_cache_update_queued(instance)

          expect { go! }.to raise_error("foo")
        end
      end
    end

    context 'when lifetime is exceeded' do
      it 'skips the calculation' do
        expect(instance).to receive(:calculate_reactive_cache).never

        go!
      end
    end

    context 'when the lease is already taken' do
      it 'skips the calculation' do
        stub_exclusive_lease_taken(cache_key)

        expect(instance).to receive(:calculate_reactive_cache).never

        go!
      end
    end
  end
end
