require 'spec_helper'

describe CacheableAttributes do
  let(:minimal_test_class) do
    Class.new do
      include ActiveModel::Model
      extend ActiveModel::Callbacks
      define_model_callbacks :commit
      include CacheableAttributes

      def self.name
        'TestClass'
      end

      def self.first
        @_first ||= new('foo' => 'a')
      end

      def self.last
        @_last ||= new('foo' => 'a', 'bar' => 'b')
      end

      attr_accessor :attributes

      def initialize(attrs = {})
        @attributes = attrs
      end
    end
  end

  shared_context 'with defaults' do
    before do
      minimal_test_class.define_singleton_method(:defaults) do
        { foo: 'a', bar: 'b', baz: 'c' }
      end
    end
  end

  describe '.current_without_cache' do
    it 'defaults to last' do
      expect(minimal_test_class.current_without_cache).to eq(minimal_test_class.last)
    end

    it 'can be overriden' do
      minimal_test_class.define_singleton_method(:current_without_cache) do
        first
      end

      expect(minimal_test_class.current_without_cache).to eq(minimal_test_class.first)
    end
  end

  describe '.cache_key' do
    it 'excludes cache attributes' do
      expect(minimal_test_class.cache_key).to eq("TestClass:#{Gitlab::VERSION}:#{Gitlab.migrations_hash}:json")
    end
  end

  describe '.defaults' do
    it 'defaults to {}' do
      expect(minimal_test_class.defaults).to eq({})
    end

    context 'with defaults defined' do
      include_context 'with defaults'

      it 'can be overriden' do
        expect(minimal_test_class.defaults).to eq({ foo: 'a', bar: 'b', baz: 'c' })
      end
    end
  end

  describe '.build_from_defaults' do
    include_context 'with defaults'

    context 'without any attributes given' do
      it 'intializes a new object with the defaults' do
        expect(minimal_test_class.build_from_defaults).not_to be_persisted
      end
    end

    context 'without attributes given' do
      it 'intializes a new object with the given attributes merged into the defaults' do
        expect(minimal_test_class.build_from_defaults(foo: 'd').attributes[:foo]).to eq('d')
      end
    end
  end

  describe '.current', :use_clean_rails_memory_store_caching do
    context 'redis unavailable' do
      it 'returns an uncached record' do
        allow(minimal_test_class).to receive(:last).and_return(:last)
        expect(Rails.cache).to receive(:read).and_raise(Redis::BaseError)

        expect(minimal_test_class.current).to eq(:last)
      end
    end

    context 'when a record is not yet present' do
      it 'does not cache nil object' do
        # when missing settings a nil object is returned, but not cached
        allow(minimal_test_class).to receive(:last).twice.and_return(nil)

        expect(minimal_test_class.current).to be_nil
        expect(Rails.cache.exist?(minimal_test_class.cache_key)).to be(false)
      end

      it 'cache non-nil object' do
        # when the settings are set the method returns a valid object
        allow(minimal_test_class).to receive(:last).and_call_original

        expect(minimal_test_class.current).to eq(minimal_test_class.last)
        expect(Rails.cache.exist?(minimal_test_class.cache_key)).to be(true)

        # subsequent calls retrieve the record from the cache
        last_record = minimal_test_class.last
        expect(minimal_test_class).not_to receive(:last)
        expect(minimal_test_class.current.attributes).to eq(last_record.attributes)
      end
    end
  end

  describe '.cached', :use_clean_rails_memory_store_caching do
    context 'when cache is cold' do
      it 'returns nil' do
        expect(minimal_test_class.cached).to be_nil
      end
    end

    context 'when cached settings do not include the latest defaults' do
      before do
        Rails.cache.write(minimal_test_class.cache_key, { bar: 'b', baz: 'c' }.to_json)
        minimal_test_class.define_singleton_method(:defaults) do
          { foo: 'a', bar: 'b', baz: 'c' }
        end
      end

      it 'includes attributes from defaults' do
        expect(minimal_test_class.cached.attributes[:foo]).to eq(minimal_test_class.defaults[:foo])
      end
    end
  end

  describe '#cache!', :use_clean_rails_memory_store_caching do
    let(:appearance_record) { create(:appearance) }

    it 'caches the attributes' do
      appearance_record.cache!

      expect(Rails.cache.read(Appearance.cache_key)).to eq(appearance_record.attributes.to_json)
    end
  end
end
