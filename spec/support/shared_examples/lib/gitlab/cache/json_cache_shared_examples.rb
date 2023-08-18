# frozen_string_literal: true

RSpec.shared_examples 'Json Cache class' do
  describe '#read' do
    it 'returns the cached value when there is data in the cache with the given key' do
      allow(backend).to receive(:read).with(expanded_key).and_return(json_value(true))

      expect(cache.read(key)).to eq(true)
    end

    it 'returns nil when there is no data in the cache with the given key' do
      allow(backend).to receive(:read).with(expanded_key).and_return(nil)

      expect(Gitlab::Json).not_to receive(:parse)
      expect(cache.read(key)).to be_nil
    end

    it 'parses the cached value' do
      allow(backend).to receive(:read).with(expanded_key).and_return(json_value(broadcast_message))

      expect(cache.read(key, System::BroadcastMessage)).to eq(broadcast_message)
    end

    it 'returns nil when klass is nil' do
      allow(backend).to receive(:read).with(expanded_key).and_return(json_value(broadcast_message))

      expect(cache.read(key)).to be_nil
    end

    it 'gracefully handles an empty hash' do
      allow(backend).to receive(:read).with(expanded_key).and_return(json_value({}))

      expect(cache.read(key, System::BroadcastMessage)).to be_a(System::BroadcastMessage)
    end

    context 'when the cached value is a JSON true value' do
      it 'parses the cached value' do
        allow(backend).to receive(:read).with(expanded_key).and_return(json_value(true))

        expect(cache.read(key, System::BroadcastMessage)).to eq(true)
      end
    end

    context 'when the cached value is a JSON false value' do
      it 'parses the cached value' do
        allow(backend).to receive(:read).with(expanded_key).and_return(json_value(false))

        expect(cache.read(key, System::BroadcastMessage)).to eq(false)
      end
    end

    context 'when the cached value is a hash' do
      it 'gracefully handles bad cached entry' do
        allow(backend).to receive(:read).with(expanded_key).and_return('{')

        expect(cache.read(key, System::BroadcastMessage)).to be_nil
      end

      it 'gracefully handles unknown attributes' do
        read_value = json_value(broadcast_message.attributes.merge(unknown_attribute: 1))
        allow(backend).to receive(:read).with(expanded_key).and_return(read_value)

        expect(cache.read(key, System::BroadcastMessage)).to be_nil
      end

      it 'gracefully handles excluded fields from attributes during serialization' do
        read_value = json_value(broadcast_message.attributes.except("message_html"))
        allow(backend).to receive(:read).with(expanded_key).and_return(read_value)

        result = cache.read(key, System::BroadcastMessage)

        System::BroadcastMessage.cached_markdown_fields.html_fields.each do |field|
          expect(result.public_send(field)).to be_nil
        end
      end
    end

    context 'when the cached value is an array' do
      it 'parses the cached value' do
        allow(backend).to receive(:read).with(expanded_key).and_return(json_value([broadcast_message]))

        expect(cache.read(key, System::BroadcastMessage)).to eq([broadcast_message])
      end

      it 'returns an empty array when klass is nil' do
        allow(backend).to receive(:read).with(expanded_key).and_return(json_value([broadcast_message]))

        expect(cache.read(key)).to eq([])
      end

      it 'gracefully handles bad cached entry' do
        allow(backend).to receive(:read).with(expanded_key).and_return('[')

        expect(cache.read(key, System::BroadcastMessage)).to be_nil
      end

      it 'gracefully handles an empty array' do
        allow(backend).to receive(:read).with(expanded_key).and_return(json_value([]))

        expect(cache.read(key, System::BroadcastMessage)).to eq([])
      end

      it 'gracefully handles items with unknown attributes' do
        read_value = json_value([{ unknown_attribute: 1 }, broadcast_message.attributes])
        allow(backend).to receive(:read).with(expanded_key).and_return(read_value)

        expect(cache.read(key, System::BroadcastMessage)).to eq([broadcast_message])
      end
    end
  end

  describe '#write' do
    it 'writes value to the cache with the given key' do
      cache.write(key, true)

      expect(backend).to have_received(:write).with(expanded_key, json_value(true), nil)
    end

    it 'writes a string containing a JSON representation of the value to the cache' do
      cache.write(key, broadcast_message)

      expect(backend).to have_received(:write).with(expanded_key, json_value(broadcast_message), nil)
    end

    it 'passes options the underlying cache implementation' do
      cache.write(key, true, expires_in: 15.seconds)

      expect(backend).to have_received(:write).with(expanded_key, json_value(true), expires_in: 15.seconds)
    end

    it 'passes options the underlying cache implementation when options is empty' do
      cache.write(key, true, {})

      expect(backend).to have_received(:write).with(expanded_key, json_value(true), {})
    end

    it 'passes options the underlying cache implementation when options is nil' do
      cache.write(key, true, nil)

      expect(backend).to have_received(:write).with(expanded_key, json_value(true), nil)
    end
  end

  # rubocop:disable Style/RedundantFetchBlock
  describe '#fetch', :use_clean_rails_memory_store_caching do
    let(:backend) { Rails.cache }

    it 'requires a block' do
      expect { cache.fetch(key) }.to raise_error(LocalJumpError)
    end

    it 'passes options the underlying cache implementation' do
      expect(backend).to receive(:write).with(expanded_key, json_value(true), { expires_in: 15.seconds })

      cache.fetch(key, { expires_in: 15.seconds }) { true }
    end

    context 'when the given key does not exist in the cache' do
      context 'when the result of the block is truthy' do
        it 'returns the result of the block' do
          result = cache.fetch(key) { true }

          expect(result).to eq(true)
        end

        it 'caches the value' do
          expect(backend).to receive(:write).with(expanded_key, json_value(true), {})

          cache.fetch(key) { true }
        end
      end

      context 'when the result of the block is false' do
        it 'returns the result of the block' do
          result = cache.fetch(key) { false }

          expect(result).to eq(false)
        end

        it 'caches the value' do
          expect(backend).to receive(:write).with(expanded_key, json_value(false), {})

          cache.fetch(key) { false }
        end
      end

      context 'when the result of the block is nil' do
        it 'returns the result of the block' do
          result = cache.fetch(key) { nil }

          expect(result).to eq(nil)
        end

        it 'caches the value' do
          expect(backend).to receive(:write).with(expanded_key, json_value(nil), {})

          cache.fetch(key) { nil }
        end
      end
    end

    context 'when the given key exists in the cache' do
      context 'when the cached value is a hash' do
        before do
          backend.write(expanded_key, json_value(broadcast_message))
        end

        it 'parses the cached value' do
          result = cache.fetch(key, as: System::BroadcastMessage) { 'block result' }

          expect(result).to eq(broadcast_message)
        end

        it 'decodes enums correctly' do
          result = cache.fetch(key, as: System::BroadcastMessage) { 'block result' }

          expect(result.broadcast_type).to eq(broadcast_message.broadcast_type)
        end

        context 'when the cached value is an instance of ActiveRecord::Base' do
          it 'returns a persisted record when id is set' do
            result = cache.fetch(key, as: System::BroadcastMessage) { 'block result' }

            expect(result).to be_persisted
          end

          it 'returns a new record when id is nil' do
            backend.write(expanded_key, json_value(build(:broadcast_message)))

            result = cache.fetch(key, as: System::BroadcastMessage) { 'block result' }

            expect(result).to be_new_record
          end

          it 'returns a new record when id is missing' do
            backend.write(expanded_key, json_value(build(:broadcast_message).attributes.except('id')))

            result = cache.fetch(key, as: System::BroadcastMessage) { 'block result' }

            expect(result).to be_new_record
          end

          it 'gracefully handles bad cached entry' do
            allow(backend).to receive(:read).with(expanded_key).and_return('{')

            result = cache.fetch(key, as: System::BroadcastMessage) { 'block result' }

            expect(result).to eq 'block result'
          end

          it 'gracefully handles an empty hash' do
            allow(backend).to receive(:read).with(expanded_key).and_return(json_value({}))

            expect(cache.fetch(key, as: System::BroadcastMessage)).to be_a(System::BroadcastMessage)
          end

          it 'gracefully handles unknown attributes' do
            read_value = json_value(broadcast_message.attributes.merge(unknown_attribute: 1))
            allow(backend).to receive(:read).with(expanded_key).and_return(read_value)

            result = cache.fetch(key, as: System::BroadcastMessage) { 'block result' }

            expect(result).to eq 'block result'
          end

          it 'gracefully handles excluded fields from attributes during serialization' do
            read_value = json_value(broadcast_message.attributes.except("message_html"))
            allow(backend).to receive(:read).with(expanded_key).and_return(read_value)

            result = cache.fetch(key, as: System::BroadcastMessage) { 'block result' }

            System::BroadcastMessage.cached_markdown_fields.html_fields.each do |field|
              expect(result.public_send(field)).to be_nil
            end
          end
        end

        it 'returns the result of the block when `as` option is nil' do
          result = cache.fetch(key, as: nil) { 'block result' }

          expect(result).to eq('block result')
        end

        it 'returns the result of the block when `as` option is missing' do
          result = cache.fetch(key) { 'block result' }

          expect(result).to eq('block result')
        end
      end

      context 'when the cached value is a array' do
        before do
          backend.write(expanded_key, json_value([broadcast_message]))
        end

        it 'parses the cached value' do
          result = cache.fetch(key, as: System::BroadcastMessage) { 'block result' }

          expect(result).to eq([broadcast_message])
        end

        it 'returns an empty array when `as` option is nil' do
          result = cache.fetch(key, as: nil) { 'block result' }

          expect(result).to eq([])
        end

        it 'returns an empty array when `as` option is not provided' do
          result = cache.fetch(key) { 'block result' }

          expect(result).to eq([])
        end
      end

      context 'when the cached value is true' do
        before do
          backend.write(expanded_key, json_value(true))
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
          backend.write(expanded_key, json_value(false))
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
          backend.write(expanded_key, json_value(nil))
        end

        it 'returns the result of the block' do
          result = cache.fetch(key) { 'block result' }

          expect(result).to eq('block result')
        end

        it 'writes the result of the block to the cache' do
          expect(backend).to receive(:write).with(expanded_key, json_value('block result'), {})

          cache.fetch(key) { 'block result' }
        end
      end
    end
  end
  # rubocop:enable Style/RedundantFetchBlock
end
