# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::JsonCache do
  let_it_be(:broadcast_message) { create(:broadcast_message) }

  let(:backend) { double('backend').as_null_object }
  let(:namespace) { 'geo' }
  let(:key) { 'foo' }
  let(:expanded_key) { "#{namespace}:#{key}:#{Gitlab::VERSION}:#{Rails.version}" }

  subject(:cache) { described_class.new(namespace: namespace, backend: backend) }

  describe '#active?' do
    context 'when backend respond to active? method' do
      it 'delegates to the underlying cache implementation' do
        backend = double('backend', active?: false)

        cache = described_class.new(namespace: namespace, backend: backend)

        expect(cache.active?).to eq(false)
      end
    end

    context 'when backend does not respond to active? method' do
      it 'returns true' do
        backend = double('backend')

        cache = described_class.new(namespace: namespace, backend: backend)

        expect(cache.active?).to eq(true)
      end
    end
  end

  describe '#cache_key' do
    context 'when namespace is not defined' do
      context 'when cache_key_with_version is true' do
        it 'expands out the key with GitLab, and Rails versions' do
          cache = described_class.new(cache_key_with_version: true)

          cache_key = cache.cache_key(key)

          expect(cache_key).to eq("#{key}:#{Gitlab::VERSION}:#{Rails.version}")
        end
      end

      context 'when cache_key_with_version is false' do
        it 'returns the key' do
          cache = described_class.new(namespace: nil, cache_key_with_version: false)

          cache_key = cache.cache_key(key)

          expect(cache_key).to eq(key)
        end
      end
    end

    context 'when namespace is nil' do
      context 'when cache_key_with_version is true' do
        it 'expands out the key with GitLab, and Rails versions' do
          cache = described_class.new(cache_key_with_version: true)

          cache_key = cache.cache_key(key)

          expect(cache_key).to eq("#{key}:#{Gitlab::VERSION}:#{Rails.version}")
        end
      end

      context 'when cache_key_with_version is false' do
        it 'returns the key' do
          cache = described_class.new(namespace: nil, cache_key_with_version: false)

          cache_key = cache.cache_key(key)

          expect(cache_key).to eq(key)
        end
      end
    end

    context 'when namespace is set' do
      context 'when cache_key_with_version is true' do
        it 'expands out the key with namespace and Rails version' do
          cache = described_class.new(namespace: namespace, cache_key_with_version: true)

          cache_key = cache.cache_key(key)

          expect(cache_key).to eq("#{namespace}:#{key}:#{Gitlab::VERSION}:#{Rails.version}")
        end
      end

      context 'when cache_key_with_version is false' do
        it 'expands out the key with namespace' do
          cache = described_class.new(namespace: namespace, cache_key_with_version: false)

          cache_key = cache.cache_key(key)

          expect(cache_key).to eq("#{namespace}:#{key}")
        end
      end
    end
  end

  describe '#expire' do
    it 'expires the given key from the cache' do
      cache.expire(key)

      expect(backend).to have_received(:delete).with(expanded_key)
    end
  end

  describe '#read' do
    it 'reads the given key from the cache' do
      cache.read(key)

      expect(backend).to have_received(:read).with(expanded_key)
    end

    it 'returns the cached value when there is data in the cache with the given key' do
      allow(backend).to receive(:read)
        .with(expanded_key)
        .and_return("true")

      expect(cache.read(key)).to eq(true)
    end

    it 'returns nil when there is no data in the cache with the given key' do
      allow(backend).to receive(:read)
        .with(expanded_key)
        .and_return(nil)

      expect(Gitlab::Json).not_to receive(:parse)
      expect(cache.read(key)).to be_nil
    end

    context 'when the cached value is true' do
      it 'parses the cached value' do
        allow(backend).to receive(:read)
          .with(expanded_key)
          .and_return(true)

        expect(Gitlab::Json).to receive(:parse).with("true").and_call_original
        expect(cache.read(key, BroadcastMessage)).to eq(true)
      end
    end

    context 'when the cached value is false' do
      it 'parses the cached value' do
        allow(backend).to receive(:read)
          .with(expanded_key)
          .and_return(false)

        expect(Gitlab::Json).to receive(:parse).with("false").and_call_original
        expect(cache.read(key, BroadcastMessage)).to eq(false)
      end
    end

    context 'when the cached value is a JSON true value' do
      it 'parses the cached value' do
        allow(backend).to receive(:read)
          .with(expanded_key)
          .and_return("true")

        expect(cache.read(key, BroadcastMessage)).to eq(true)
      end
    end

    context 'when the cached value is a JSON false value' do
      it 'parses the cached value' do
        allow(backend).to receive(:read)
          .with(expanded_key)
          .and_return("false")

        expect(cache.read(key, BroadcastMessage)).to eq(false)
      end
    end

    context 'when the cached value is a hash' do
      it 'parses the cached value' do
        allow(backend).to receive(:read)
          .with(expanded_key)
          .and_return(broadcast_message.to_json)

        expect(cache.read(key, BroadcastMessage)).to eq(broadcast_message)
      end

      it 'returns nil when klass is nil' do
        allow(backend).to receive(:read)
          .with(expanded_key)
          .and_return(broadcast_message.to_json)

        expect(cache.read(key)).to be_nil
      end

      it 'gracefully handles bad cached entry' do
        allow(backend).to receive(:read)
          .with(expanded_key)
          .and_return('{')

        expect(cache.read(key, BroadcastMessage)).to be_nil
      end

      it 'gracefully handles an empty hash' do
        allow(backend).to receive(:read)
          .with(expanded_key)
          .and_return('{}')

        expect(cache.read(key, BroadcastMessage)).to be_a(BroadcastMessage)
      end

      it 'gracefully handles unknown attributes' do
        allow(backend).to receive(:read)
          .with(expanded_key)
          .and_return(broadcast_message.attributes.merge(unknown_attribute: 1).to_json)

        expect(cache.read(key, BroadcastMessage)).to be_nil
      end

      it 'gracefully handles excluded fields from attributes during serialization' do
        allow(backend).to receive(:read)
          .with(expanded_key)
          .and_return(broadcast_message.attributes.except("message_html").to_json)

        result = cache.read(key, BroadcastMessage)

        BroadcastMessage.cached_markdown_fields.html_fields.each do |field|
          expect(result.public_send(field)).to be_nil
        end
      end
    end

    context 'when the cached value is an array' do
      it 'parses the cached value' do
        allow(backend).to receive(:read)
          .with(expanded_key)
          .and_return([broadcast_message].to_json)

        expect(cache.read(key, BroadcastMessage)).to eq([broadcast_message])
      end

      it 'returns an empty array when klass is nil' do
        allow(backend).to receive(:read)
          .with(expanded_key)
          .and_return([broadcast_message].to_json)

        expect(cache.read(key)).to eq([])
      end

      it 'gracefully handles bad cached entry' do
        allow(backend).to receive(:read)
          .with(expanded_key)
          .and_return('[')

        expect(cache.read(key, BroadcastMessage)).to be_nil
      end

      it 'gracefully handles an empty array' do
        allow(backend).to receive(:read)
          .with(expanded_key)
          .and_return('[]')

        expect(cache.read(key, BroadcastMessage)).to eq([])
      end

      it 'gracefully handles unknown attributes' do
        allow(backend).to receive(:read)
          .with(expanded_key)
          .and_return([{ unknown_attribute: 1 }, broadcast_message.attributes].to_json)

        expect(cache.read(key, BroadcastMessage)).to eq([broadcast_message])
      end
    end
  end

  describe '#write' do
    it 'writes value to the cache with the given key' do
      cache.write(key, true)

      expect(backend).to have_received(:write).with(expanded_key, "true", nil)
    end

    it 'writes a string containing a JSON representation of the value to the cache' do
      cache.write(key, broadcast_message)

      expect(backend).to have_received(:write)
        .with(expanded_key, broadcast_message.to_json, nil)
    end

    it 'passes options the underlying cache implementation' do
      cache.write(key, true, expires_in: 15.seconds)

      expect(backend).to have_received(:write)
        .with(expanded_key, "true", expires_in: 15.seconds)
    end

    it 'passes options the underlying cache implementation when options is empty' do
      cache.write(key, true, {})

      expect(backend).to have_received(:write)
        .with(expanded_key, "true", {})
    end

    it 'passes options the underlying cache implementation when options is nil' do
      cache.write(key, true, nil)

      expect(backend).to have_received(:write)
        .with(expanded_key, "true", nil)
    end
  end

  describe '#fetch', :use_clean_rails_memory_store_caching do
    let(:backend) { Rails.cache }

    it 'requires a block' do
      expect { cache.fetch(key) }.to raise_error(LocalJumpError)
    end

    it 'passes options the underlying cache implementation' do
      expect(backend).to receive(:write)
        .with(expanded_key, "true", expires_in: 15.seconds)

      cache.fetch(key, expires_in: 15.seconds) { true }
    end

    context 'when the given key does not exist in the cache' do
      context 'when the result of the block is truthy' do
        it 'returns the result of the block' do
          result = cache.fetch(key) { true }

          expect(result).to eq(true)
        end

        it 'caches the value' do
          expect(backend).to receive(:write).with(expanded_key, "true", {})

          cache.fetch(key) { true }
        end
      end

      context 'when the result of the block is false' do
        it 'returns the result of the block' do
          result = cache.fetch(key) { false }

          expect(result).to eq(false)
        end

        it 'caches the value' do
          expect(backend).to receive(:write).with(expanded_key, "false", {})

          cache.fetch(key) { false }
        end
      end

      context 'when the result of the block is nil' do
        it 'returns the result of the block' do
          result = cache.fetch(key) { nil }

          expect(result).to eq(nil)
        end

        it 'caches the value' do
          expect(backend).to receive(:write).with(expanded_key, "null", {})

          cache.fetch(key) { nil }
        end
      end
    end

    context 'when the given key exists in the cache' do
      context 'when the cached value is a hash' do
        before do
          backend.write(expanded_key, broadcast_message.to_json)
        end

        it 'parses the cached value' do
          result = cache.fetch(key, as: BroadcastMessage) { 'block result' }

          expect(result).to eq(broadcast_message)
        end

        it 'decodes enums correctly' do
          result = cache.fetch(key, as: BroadcastMessage) { 'block result' }

          expect(result.broadcast_type).to eq(broadcast_message.broadcast_type)
        end

        context 'when the cached value is an instance of ActiveRecord::Base' do
          it 'returns a persisted record when id is set' do
            backend.write(expanded_key, broadcast_message.to_json)

            result = cache.fetch(key, as: BroadcastMessage) { 'block result' }

            expect(result).to be_persisted
          end

          it 'returns a new record when id is nil' do
            backend.write(expanded_key, build(:broadcast_message).to_json)

            result = cache.fetch(key, as: BroadcastMessage) { 'block result' }

            expect(result).to be_new_record
          end

          it 'returns a new record when id is missing' do
            backend.write(expanded_key, build(:broadcast_message).attributes.except('id').to_json)

            result = cache.fetch(key, as: BroadcastMessage) { 'block result' }

            expect(result).to be_new_record
          end

          it 'gracefully handles bad cached entry' do
            allow(backend).to receive(:read)
              .with(expanded_key)
              .and_return('{')

            result = cache.fetch(key, as: BroadcastMessage) { 'block result' }

            expect(result).to eq 'block result'
          end

          it 'gracefully handles an empty hash' do
            allow(backend).to receive(:read)
              .with(expanded_key)
              .and_return('{}')

            expect(cache.fetch(key, as: BroadcastMessage)).to be_a(BroadcastMessage)
          end

          it 'gracefully handles unknown attributes' do
            allow(backend).to receive(:read)
              .with(expanded_key)
              .and_return(broadcast_message.attributes.merge(unknown_attribute: 1).to_json)

            result = cache.fetch(key, as: BroadcastMessage) { 'block result' }

            expect(result).to eq 'block result'
          end

          it 'gracefully handles excluded fields from attributes during serialization' do
            allow(backend).to receive(:read)
              .with(expanded_key)
              .and_return(broadcast_message.attributes.except("message_html").to_json)

            result = cache.fetch(key, as: BroadcastMessage) { 'block result' }

            BroadcastMessage.cached_markdown_fields.html_fields.each do |field|
              expect(result.public_send(field)).to be_nil
            end
          end
        end

        it "returns the result of the block when 'as' option is nil" do
          result = cache.fetch(key, as: nil) { 'block result' }

          expect(result).to eq('block result')
        end

        it "returns the result of the block when 'as' option is missing" do
          result = cache.fetch(key) { 'block result' }

          expect(result).to eq('block result')
        end
      end

      context 'when the cached value is a array' do
        before do
          backend.write(expanded_key, [broadcast_message].to_json)
        end

        it 'parses the cached value' do
          result = cache.fetch(key, as: BroadcastMessage) { 'block result' }

          expect(result).to eq([broadcast_message])
        end

        it "returns an empty array when 'as' option is nil" do
          result = cache.fetch(key, as: nil) { 'block result' }

          expect(result).to eq([])
        end

        it "returns an empty array when 'as' option is not informed" do
          result = cache.fetch(key) { 'block result' }

          expect(result).to eq([])
        end
      end

      context 'when the cached value is true' do
        before do
          backend.write(expanded_key, "true")
        end

        it 'returns the cached value' do
          result = cache.fetch(key) { 'block result' }

          expect(result).to eq(true)
        end

        it 'does not execute the block' do
          expect { |block| cache.fetch(key, &block) }.not_to yield_control
        end

        it 'does not write to the cache' do
          expect(backend).not_to receive(:write)

          cache.fetch(key) { 'block result' }
        end
      end

      context 'when the cached value is false' do
        before do
          backend.write(expanded_key, "false")
        end

        it 'returns the cached value' do
          result = cache.fetch(key) { 'block result' }

          expect(result).to eq(false)
        end

        it 'does not execute the block' do
          expect { |block| cache.fetch(key, &block) }.not_to yield_control
        end

        it 'does not write to the cache' do
          expect(backend).not_to receive(:write)

          cache.fetch(key) { 'block result' }
        end
      end

      context 'when the cached value is nil' do
        before do
          backend.write(expanded_key, "null")
        end

        it 'returns the result of the block' do
          result = cache.fetch(key) { 'block result' }

          expect(result).to eq('block result')
        end

        it 'writes the result of the block to the cache' do
          expect(backend).to receive(:write)
            .with(expanded_key, 'block result'.to_json, {})

          cache.fetch(key) { 'block result' }
        end
      end
    end
  end
end
