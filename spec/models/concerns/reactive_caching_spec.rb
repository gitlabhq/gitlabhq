# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReactiveCaching, :use_clean_rails_memory_store_caching do
  include ExclusiveLeaseHelpers
  include ReactiveCachingHelpers

  let(:cache_class_test) do
    Class.new do
      include ReactiveCaching

      self.reactive_cache_key = ->(thing) { ["foo", thing.id] }

      self.reactive_cache_lifetime = 5.minutes
      self.reactive_cache_refresh_interval = 15.seconds
      self.reactive_cache_work_type = :no_dependency

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
  end

  let(:external_dependency_cache_class_test) do
    Class.new(cache_class_test) do
      self.reactive_cache_work_type = :external_dependency
    end
  end

  let(:calculation) { -> { 2 + 2 } }
  let(:cache_key) { "foo:666" }
  let(:instance) { cache_class_test.new(666, &calculation) }

  describe '#with_reactive_cache' do
    before do
      stub_reactive_cache
    end

    subject(:go!) { instance.result }

    shared_examples 'reactive worker call' do |worker_class|
      let(:instance) do
        test_class.new(666, &calculation)
      end

      it 'performs caching with correct worker' do
        expect(worker_class).to receive(:perform_async).with(test_class, 666)

        go!
      end
    end

    shared_examples 'a cacheable value' do |cached_value|
      before do
        stub_reactive_cache(instance, cached_value)
      end

      it { is_expected.to eq(cached_value) }

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

        it_behaves_like 'reactive worker call', ReactiveCachingWorker do
          let(:test_class) { cache_class_test }
        end

        it_behaves_like 'reactive worker call', ExternalServiceReactiveCachingWorker do
          let(:test_class) { external_dependency_cache_class_test }
        end
      end
    end

    context 'when cache is empty' do
      it { is_expected.to be_nil }

      it_behaves_like 'reactive worker call', ReactiveCachingWorker do
        let(:test_class) { cache_class_test }
      end

      it_behaves_like 'reactive worker call', ExternalServiceReactiveCachingWorker do
        let(:test_class) { external_dependency_cache_class_test }
      end

      it 'updates the cache lifespan' do
        expect(reactive_cache_alive?(instance)).to be_falsy

        go!

        expect(reactive_cache_alive?(instance)).to be_truthy
      end
    end

    context 'when the cache is full' do
      it_behaves_like 'a cacheable value', 4
    end

    context 'when the cache contains non-nil but blank value' do
      it_behaves_like 'a cacheable value', false
    end

    context 'when the cache contains nil value' do
      it_behaves_like 'a cacheable value', nil
    end
  end

  describe '#with_reactive_cache_set', :use_clean_rails_redis_caching do
    subject(:go!) do
      instance.with_reactive_cache_set('resource', {}) do |data|
        data
      end
    end

    it 'calls with_reactive_cache' do
      expect(instance)
        .to receive(:with_reactive_cache)

      go!
    end

    context 'data returned' do
      let(:resource) { 'resource' }
      let(:set_key) { "#{cache_key}:#{resource}" }
      let(:set_cache) { Gitlab::ReactiveCacheSetCache.new }

      before do
        stub_reactive_cache(instance, true, resource, {})
      end

      it 'saves keys in set' do
        expect(set_cache.read(set_key)).to be_empty

        go!

        expect(set_cache.read(set_key)).not_to be_empty
      end

      it 'returns the data' do
        expect(go!).to eq(true)
      end
    end
  end

  describe '.reactive_cache_worker_finder' do
    context 'with default reactive_cache_worker_finder' do
      let(:args) { %w[other args] }

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
      let(:args) { %w[arg1 arg2] }
      let(:instance) { custom_finder_cache_test.new(666, &calculation) }

      let(:custom_finder_cache_test) do
        Class.new(cache_class_test) do
          self.reactive_cache_worker_finder = ->(_id, *args) { from_cache(*args) }

          def self.from_cache(*args); end
        end
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

    shared_examples 'successful cache' do
      it 'caches the result of #calculate_reactive_cache' do
        go!

        expect(read_reactive_cache(instance)).to eq(calculation.call)
      end

      it 'does not raise the exception' do
        expect { go! }.not_to raise_exception
      end
    end

    context 'when the lease is free and lifetime is not exceeded' do
      before do
        stub_reactive_cache(instance, 'preexisting')
      end

      it_behaves_like 'successful cache'

      it 'takes and releases the lease' do
        expect_to_obtain_exclusive_lease(cache_key, 'uuid')
        expect_to_cancel_exclusive_lease(cache_key, 'uuid')

        go!
      end

      it 'enqueues a repeat worker' do
        expect_reactive_cache_update_queued(instance)

        go!
      end

      context 'when :external_dependency cache' do
        let(:instance) do
          external_dependency_cache_class_test.new(666, &calculation)
        end

        it 'enqueues a repeat worker' do
          expect_reactive_cache_update_queued(instance, worker_klass: ExternalServiceReactiveCachingWorker)

          go!
        end
      end

      it 'calls a reactive_cache_updated only once if content did not change on subsequent update' do
        expect(instance).to receive(:calculate_reactive_cache).twice
        expect(instance).to receive(:reactive_cache_updated).once

        2.times { instance.exclusively_update_reactive_cache! }
      end

      it 'does not delete the value key' do
        expect(Rails.cache).not_to receive(:delete).with(cache_key)

        go!
      end

      context 'when reactive_cache_hard_limit is set' do
        let(:test_class) { Class.new(cache_class_test) { self.reactive_cache_hard_limit = 1.megabyte } }
        let(:instance) { test_class.new(666, &calculation) }

        context 'when cache size is over the overridden limit' do
          let(:calculation) { -> { 'a' * 2 * 1.megabyte } }

          it 'raises ExceededReactiveCacheLimit exception and does not cache new data' do
            expect { go! }.to raise_exception(ReactiveCaching::ExceededReactiveCacheLimit)

            expect(read_reactive_cache(instance)).not_to eq(calculation.call)
          end

          context 'when reactive_cache_limit_enabled? is overridden to return false' do
            before do
              allow(instance).to receive(:reactive_cache_limit_enabled?).and_return(false)
            end

            it_behaves_like 'successful cache'
          end
        end

        context 'when cache size is within the overridden limit' do
          let(:calculation) { -> { 'Smaller than 1Mb reactive_cache_hard_limit' } }

          it_behaves_like 'successful cache'
        end
      end

      context 'and #calculate_reactive_cache raises an exception' do
        before do
          stub_reactive_cache(instance, "preexisting")
        end

        let(:calculation) { -> { raise "foo" } }

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
        expect(instance).not_to receive(:calculate_reactive_cache)

        go!
      end

      it 'deletes the value key' do
        expect(Rails.cache).to receive(:delete).with(cache_key).once

        go!
      end
    end

    context 'when the lease is already taken' do
      it 'skips the calculation' do
        stub_exclusive_lease_taken(cache_key)

        expect(instance).not_to receive(:calculate_reactive_cache)

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
    it { expect(subject.reactive_cache_hard_limit).to be_nil }
    it { expect(subject.reactive_cache_worker_finder).to respond_to(:call) }
  end

  describe 'classes including this concern' do
    it 'sets reactive_cache_work_type', :eager_load do
      classes = ObjectSpace.each_object(Class).select do |klass|
        klass < described_class && klass.name
      end

      expect(classes).to all(have_attributes(reactive_cache_work_type: be_in(described_class::WORK_TYPE.keys)))
    end
  end
end
