# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RedisCommands::Recorder, :use_clean_rails_redis_caching do
  subject(:recorder) { described_class.new(pattern: pattern) }

  let(:cache) { Rails.cache }
  let(:pattern) { nil }

  describe '#initialize' do
    context 'with a block' do
      it 'records Redis commands' do
        recorder = described_class.new { cache.read('key1') }

        expect(recorder.log).to include(['get', 'cache:gitlab:key1'])
      end
    end

    context 'without block' do
      it 'only initializes the recorder' do
        recorder = described_class.new

        expect(recorder.log).to eq([])
      end
    end
  end

  describe '#record' do
    it 'records Redis commands' do
      recorder.record do
        cache.write('key1', '1')
        cache.read('key1')
        cache.read('key2')
        cache.delete('key1')
      end

      expect(recorder.log).to include(['set', 'cache:gitlab:key1', anything, anything, anything])
      expect(recorder.log).to include(['get', 'cache:gitlab:key1'])
      expect(recorder.log).to include(['get', 'cache:gitlab:key2'])
      expect(recorder.log).to include(['del', 'cache:gitlab:key1'])
    end

    it 'does not record commands before the call' do
      cache.write('key1', 1)

      recorder.record do
        cache.read('key1')
      end

      expect(recorder.log).not_to include(['set', anything, anything])
      expect(recorder.log).to include(['get', 'cache:gitlab:key1'])
    end

    it 'refreshes recording after reinitialization' do
      cache.read('key1')

      recorder1 = described_class.new
      recorder1.record do
        cache.read('key2')
      end

      recorder2 = described_class.new

      cache.read('key3')

      recorder2.record do
        cache.read('key4')
      end

      expect(recorder1.log).to include(['get', 'cache:gitlab:key2'])
      expect(recorder1.log).not_to include(['get', 'cache:gitlab:key1'])
      expect(recorder1.log).not_to include(['get', 'cache:gitlab:key3'])
      expect(recorder1.log).not_to include(['get', 'cache:gitlab:key4'])

      expect(recorder2.log).to include(['get', 'cache:gitlab:key4'])
      expect(recorder2.log).not_to include(['get', 'cache:gitlab:key1'])
      expect(recorder2.log).not_to include(['get', 'cache:gitlab:key2'])
      expect(recorder2.log).not_to include(['get', 'cache:gitlab:key3'])
    end
  end

  describe 'Pattern recording' do
    let(:pattern) { 'key1' }

    it 'records only matching keys' do
      recorder.record do
        cache.write('key1', '1')
        cache.read('key2')
        cache.read('key1')
        cache.delete('key2')
      end

      expect(recorder.log).to include(['set', 'cache:gitlab:key1', anything, anything, anything])
      expect(recorder.log).to include(['get', 'cache:gitlab:key1'])
      expect(recorder.log).not_to include(['get', 'cache:gitlab:key2'])
      expect(recorder.log).not_to include(['del', 'cache:gitlab:key2'])
    end
  end

  describe '#by_command' do
    it 'returns only matching commands' do
      recorder.record do
        cache.write('key1', '1')
        cache.read('key2')
        cache.read('key1')
        cache.delete('key2')
      end

      expect(recorder.by_command('del')).to match_array([['del', 'cache:gitlab:key2']])
    end
  end

  describe '#count' do
    it 'returns the number of recorded commands' do
      cache.read 'warmup'

      recorder.record do
        cache.write('key1', '1')
        cache.read('key2')
        cache.read('key1')
        cache.delete('key2')
      end

      expect(recorder.count).to eq(4)
    end
  end
end
