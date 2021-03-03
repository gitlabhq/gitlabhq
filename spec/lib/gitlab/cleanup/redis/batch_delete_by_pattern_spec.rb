# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cleanup::Redis::BatchDeleteByPattern, :clean_gitlab_redis_cache do
  subject { described_class.new(patterns) }

  describe 'execute' do
    context 'when no patterns are passed' do
      before do
        expect(Gitlab::Redis::Cache).not_to receive(:with)
      end

      context 'with nil patterns' do
        let(:patterns) { nil }

        specify { expect { subject }.to raise_error(ArgumentError, 'Argument should be an Array of patterns') }
      end

      context 'with empty array patterns' do
        let(:patterns) { [] }

        specify { subject.execute }
      end
    end

    context 'with patterns' do
      context 'when key is not found' do
        let(:patterns) { ['key'] }

        before do
          expect_any_instance_of(Redis).not_to receive(:del) # rubocop:disable RSpec/AnyInstanceOf
        end

        specify { subject.execute }
      end

      context 'with cache data' do
        let(:cache_keys) { %w[key-test1 key-test2 key-test3 key-test4] }

        before do
          stub_const("#{described_class}::REDIS_CLEAR_BATCH_SIZE", 2)

          write_to_cache
        end

        context 'with one key' do
          let(:patterns) { ['key-test1'] }

          it 'deletes the key' do
            expect_any_instance_of(Redis).to receive(:del).with(patterns.first).once # rubocop:disable RSpec/AnyInstanceOf

            subject.execute
          end
        end

        context 'with many keys' do
          let(:patterns) { %w[key-test1 key-test2] }

          it 'deletes keys for each pattern separatelly' do
            expect_any_instance_of(Redis).to receive(:del).with(patterns.first).once # rubocop:disable RSpec/AnyInstanceOf
            expect_any_instance_of(Redis).to receive(:del).with(patterns.last).once # rubocop:disable RSpec/AnyInstanceOf

            subject.execute
          end
        end

        context 'with cache_keys over batch size' do
          let(:patterns) { %w[key-test*] }

          it 'deletes matched keys in batches' do
            # redis scan returns the values in random order so just checking it is being called twice meaning
            # scan returned results in 2 batches, which is what we expect
            key_like = start_with('key-test')
            expect_any_instance_of(Redis).to receive(:del).with(key_like, key_like).twice # rubocop:disable RSpec/AnyInstanceOf

            subject.execute
          end
        end
      end
    end
  end
end

def write_to_cache
  Gitlab::Redis::Cache.with do |redis|
    cache_keys.each_with_index do |cache_key, index|
      redis.set(cache_key, index)
    end
  end
end
