# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::MarkdownCache::Redis::Store, :clean_gitlab_redis_cache do
  let(:storable_class) do
    Class.new do
      cattr_reader :cached_markdown_fields do
        Gitlab::MarkdownCache::FieldData.new.tap do |field_data|
          field_data[:field_1] = {}
          field_data[:field_2] = {}
        end
      end

      attr_accessor :field_1, :field_2, :field_1_html, :field_2_html, :cached_markdown_version

      def cache_key
        "cache-key"
      end
    end
  end

  let(:storable) { storable_class.new }
  let(:cache_key) { "markdown_cache:#{storable.cache_key}" }

  subject(:store) { described_class.new(storable) }

  def read_values
    Gitlab::Redis::Cache.with do |r|
      r.mapped_hmget(cache_key,
                     :field_1_html, :field_2_html, :cached_markdown_version)
    end
  end

  def store_values(values)
    Gitlab::Redis::Cache.with do |r|
      r.mapped_hmset(cache_key,
                     values)
    end
  end

  describe '.bulk_read' do
    before do
      store.save(field_1_html: "hello", field_2_html: "world", cached_markdown_version: 1) # rubocop:disable Rails/SaveBang
    end

    it 'returns a hash of values from store' do
      Gitlab::Redis::Cache.with do |redis|
        expect(redis).to receive(:pipelined).and_call_original
      end

      results = described_class.bulk_read([storable])

      expect(results[storable.cache_key].value.symbolize_keys)
        .to eq(field_1_html: "hello", field_2_html: "world", cached_markdown_version: "1")
    end
  end

  describe '#save' do
    it 'stores updates to html fields and version' do
      values_to_store = { field_1_html: "hello", field_2_html: "world", cached_markdown_version: 1 }

      store.save(values_to_store) # rubocop:disable Rails/SaveBang

      expect(read_values)
        .to eq(field_1_html: "hello", field_2_html: "world", cached_markdown_version: "1")
    end
  end

  describe '#read' do
    it 'reads the html fields and version from redis if they were stored' do
      stored_values = { field_1_html: "hello", field_2_html: "world", cached_markdown_version: 1 }

      store_values(stored_values)

      expect(store.read.symbolize_keys)
        .to eq(field_1_html: "hello", field_2_html: "world", cached_markdown_version: "1")
    end

    it 'is mared loaded after reading' do
      expect(store).not_to be_loaded

      store.read

      expect(store).to be_loaded
    end
  end
end
