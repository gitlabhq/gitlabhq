# frozen_string_literal: true

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

    def self.primary_key
      :id
    end

    def initialize(id, &blk)
      @id = id
      @calculator = blk
    end

    def calculate_reactive_cache
      @calculator.call
    end

    def result
      with_reactive_cache do |data|
        data
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

      it { is_expected.to eq(4) }

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

      context 'when cache was invalidated' do
        it 'refreshes cache' do
          expect(ReactiveCachingWorker).to receive(:perform_async).with(CacheTest, 666)

          instance.with_reactive_cache { raise described_class::InvalidateReactiveCache }
        end
      end
    end

    context 'when cache contains non-nil but blank value' do
      before do
        stub_reactive_cache(instance, false)
      end

      it { is_expected.to eq(false) }
    end
  end

  describe '.reactive_cache_worker_finder' do
    context 'with default reactive_cache_worker_finder' do
      let(:args) { %w(other args) }

      before do
        allow(instance.class).to receive(:find_by).with(id: instance.id)
          .and_return(instance)
      end

      it 'calls the activerecord find_by method' do
        result = instance.class.reactive_cache_worker_finder.call(instance.id, *args)

        expect(result).to eq(instance)
        expect(instance.class).to have_received(:find_by).with(id: instance.id)
      end
    end

    context 'with custom reactive_cache_worker_finder' do
      let(:args) { %w(arg1 arg2) }
      let(:instance) { CustomFinderCacheTest.new(666, &calculation) }

      class CustomFinderCacheTest < CacheTest
        self.reactive_cache_worker_finder = ->(_id, *args) { from_cache(*args) }

        def self.from_cache(*args); end
      end

      before do
        allow(instance.class).to receive(:from_cache).with(*args).and_return(instance)
      end

      it 'overrides the default reactive_cache_worker_finder' do
        result = instance.class.reactive_cache_worker_finder.call(instance.id, *args)

        expect(result).to eq(instance)
        expect(instance.class).to have_received(:from_cache).with(*args)
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

        it 'does not enqueue a repeat worker' do
          expect(ReactiveCachingWorker)
            .not_to receive(:perform_in)

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

  describe 'default options' do
    let(:cached_class) { Class.new { include ReactiveCaching } }

    subject { cached_class.new }

    it { expect(subject.reactive_cache_lease_timeout).to be_a(ActiveSupport::Duration) }
    it { expect(subject.reactive_cache_refresh_interval).to be_a(ActiveSupport::Duration) }
    it { expect(subject.reactive_cache_lifetime).to be_a(ActiveSupport::Duration) }

    it { expect(subject.reactive_cache_key).to respond_to(:call) }
    it { expect(subject.reactive_cache_worker_finder).to respond_to(:call) }
  end
end
