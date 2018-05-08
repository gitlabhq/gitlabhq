require 'spec_helper'

describe ReactiveCaching, :use_clean_rails_memory_store_caching do
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

  let(:now) { Time.now.utc }

  around do |example|
    Timecop.freeze(now) { example.run }
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

      it 'queues a background worker' do
        expect(ReactiveCachingWorker).to receive(:perform_async).with(CacheTest, 666)

        go!
      end

      it 'updates the cache lifespan' do
        go!

        expect(reactive_cache_alive?(instance)).to be_truthy
      end
    end

    context 'when the cache is full' do
      before do
        stub_reactive_cache(instance, 4)
      end

      it { is_expected.to eq(2) }

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
  end

  describe '#exclusively_update_reactive_cache!' do
    subject(:go!) { instance.exclusively_update_reactive_cache! }

    context 'when the lease is free and lifetime is not exceeded' do
      before do
        stub_reactive_cache(instance, "preexisting")
      end

      it 'takes and releases the lease' do
        expect_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return("000000")
        expect(Gitlab::ExclusiveLease).to receive(:cancel).with(cache_key, "000000")

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
      before do
        expect_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return(nil)
      end

      it 'skips the calculation' do
        expect(instance).to receive(:calculate_reactive_cache).never

        go!
      end
    end
  end
end
