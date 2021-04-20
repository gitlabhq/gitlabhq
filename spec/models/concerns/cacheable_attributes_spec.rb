# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CacheableAttributes do
  let(:minimal_test_class) do
    Class.new do
      include ActiveModel::Model
      extend ActiveModel::Callbacks
      include ActiveModel::AttributeMethods
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

      def self.column_names
        %w[foo bar baz]
      end

      attr_accessor :attributes

      def initialize(attrs = {}, *)
        @attributes = attrs
      end
    end
  end

  before do
    stub_const("MinimalTestClass", minimal_test_class)
  end

  shared_context 'with defaults' do
    before do
      MinimalTestClass.define_singleton_method(:defaults) do
        { foo: 'a', bar: 'b', baz: 'c' }
      end
    end
  end

  describe '.expire', :use_clean_rails_memory_store_caching, :request_store do
    it 'wipes the cache' do
      obj = MinimalTestClass.new
      obj.cache!
      expect(MinimalTestClass.cached).not_to eq(nil)

      MinimalTestClass.expire

      expect(MinimalTestClass.cached).to eq(nil)
    end
  end

  describe '.current_without_cache' do
    it 'defaults to last' do
      expect(MinimalTestClass.current_without_cache).to eq(MinimalTestClass.last)
    end

    it 'can be overridden' do
      MinimalTestClass.define_singleton_method(:current_without_cache) do
        first
      end

      expect(MinimalTestClass.current_without_cache).to eq(MinimalTestClass.first)
    end
  end

  describe '.cache_key' do
    it 'excludes cache attributes' do
      expect(MinimalTestClass.cache_key).to eq("TestClass:#{Gitlab::VERSION}:#{Rails.version}")
    end
  end

  describe '.defaults' do
    it 'defaults to {}' do
      expect(MinimalTestClass.defaults).to eq({})
    end

    context 'with defaults defined' do
      include_context 'with defaults'

      it 'can be overridden' do
        expect(MinimalTestClass.defaults).to eq({ foo: 'a', bar: 'b', baz: 'c' })
      end
    end
  end

  describe '.build_from_defaults' do
    include_context 'with defaults'

    context 'without any attributes given' do
      it 'intializes a new object with the defaults' do
        expect(MinimalTestClass.build_from_defaults.attributes).to eq(MinimalTestClass.defaults.stringify_keys)
      end
    end

    context 'with attributes given' do
      it 'intializes a new object with the given attributes merged into the defaults' do
        expect(MinimalTestClass.build_from_defaults(foo: 'd').attributes['foo']).to eq('d')
      end
    end

    describe 'edge cases on concrete implementations' do
      describe '.build_from_defaults' do
        context 'without any attributes given' do
          it 'intializes all attributes even if they are nil' do
            record = ApplicationSetting.build_from_defaults

            expect(record).not_to be_persisted
            expect(record.sign_in_text).to be_nil
          end
        end
      end
    end
  end

  describe '.current', :use_clean_rails_memory_store_caching do
    context 'redis unavailable' do
      before do
        allow(MinimalTestClass).to receive(:last).and_return(:last)
        expect(Rails.cache).to receive(:read).with(MinimalTestClass.cache_key).and_raise(Redis::BaseError)
      end

      context 'in production environment' do
        before do
          stub_rails_env('production')
        end

        it 'returns an uncached record and logs a warning' do
          expect(Gitlab::AppLogger).to receive(:warn).with("Cached record for TestClass couldn't be loaded, falling back to uncached record: Redis::BaseError")

          expect(MinimalTestClass.current).to eq(:last)
        end
      end

      context 'in other environments' do
        before do
          stub_rails_env('development')
        end

        it 'returns an uncached record and logs a warning' do
          expect(Gitlab::AppLogger).not_to receive(:warn)

          expect { MinimalTestClass.current }.to raise_error(Redis::BaseError)
        end
      end
    end

    context 'when a record is not yet present' do
      it 'does not cache nil object' do
        # when missing settings a nil object is returned, but not cached
        allow(ApplicationSetting).to receive(:current_without_cache).twice.and_return(nil)

        expect(ApplicationSetting.current).to be_nil
        expect(ApplicationSetting.cache_backend.exist?(ApplicationSetting.cache_key)).to be(false)
      end

      it 'caches non-nil object' do
        create(:application_setting)

        expect(ApplicationSetting.current).to eq(ApplicationSetting.last)
        expect(ApplicationSetting.cache_backend.exist?(ApplicationSetting.cache_key)).to be(true)

        # subsequent calls retrieve the record from the cache
        last_record = ApplicationSetting.last
        expect(ApplicationSetting).not_to receive(:current_without_cache)
        expect(ApplicationSetting.current.attributes).to eq(last_record.attributes)
      end
    end

    describe 'edge cases' do
      describe 'caching behavior', :use_clean_rails_memory_store_caching do
        before do
          stub_commonmark_sourcepos_disabled
        end

        it 'retrieves upload fields properly' do
          ar_record = create(:appearance, :with_logo)
          ar_record.cache!

          cache_record = Appearance.current

          expect(cache_record).to be_persisted
          expect(cache_record.logo).to be_an(AttachmentUploader)
          expect(cache_record.logo.url).to end_with('/dk.png')
        end

        it 'retrieves markdown fields properly' do
          ar_record = create(:appearance, description: '**Hello**')
          ar_record.cache!

          cache_record = Appearance.current

          expect(cache_record.description).to eq('**Hello**')
          expect(cache_record.description_html).to eq('<p dir="auto"><strong>Hello</strong></p>')
        end
      end
    end

    it 'uses RequestStore in addition to process memory cache', :request_store, :do_not_mock_admin_mode_setting do
      # Warm up the cache
      create(:application_setting).cache!

      expect(ApplicationSetting.cache_backend).to eq(Gitlab::ProcessMemoryCache.cache_backend)
      expect(ApplicationSetting.cache_backend).to receive(:read).with(ApplicationSetting.cache_key).once.and_call_original

      2.times { ApplicationSetting.current }
    end
  end

  describe '.cached', :use_clean_rails_memory_store_caching do
    context 'when cache is cold' do
      it 'returns nil' do
        expect(MinimalTestClass.cached).to be_nil
      end
    end

    context 'when cached is warm' do
      before do
        # Warm up the cache
        create(:appearance).cache!
      end

      it 'retrieves the record from cache' do
        expect(ActiveRecord::QueryRecorder.new { Appearance.cached }.count).to eq(0)
        expect(Appearance.cached).to eq(Appearance.current_without_cache)
      end
    end
  end

  describe '#cache!', :use_clean_rails_memory_store_caching do
    let(:record) { create(:appearance) }

    it 'caches the attributes' do
      record.cache!

      expect(Rails.cache.read(Appearance.cache_key)).to eq(record)
    end

    describe 'edge cases' do
      let(:record) { create(:appearance) }

      it 'caches the attributes' do
        record.cache!

        expect(Rails.cache.read(Appearance.cache_key)).to eq(record)
      end
    end
  end
end
