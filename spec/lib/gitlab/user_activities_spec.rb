require 'spec_helper'

describe Gitlab::UserActivities, :clean_gitlab_redis_shared_state do
  let(:now) { Time.now }

  describe '.record' do
    context 'with no time given' do
      it 'uses Time.now and records an activity in SharedState' do
        Timecop.freeze do
          now # eager-load now
          described_class.record(42)
        end

        Gitlab::Redis::SharedState.with do |redis|
          expect(redis.hscan(described_class::KEY, 0)).to eq(['0', [['42', now.to_i.to_s]]])
        end
      end
    end

    context 'with a time given' do
      it 'uses the given time and records an activity in SharedState' do
        described_class.record(42, now)

        Gitlab::Redis::SharedState.with do |redis|
          expect(redis.hscan(described_class::KEY, 0)).to eq(['0', [['42', now.to_i.to_s]]])
        end
      end
    end
  end

  describe '.delete' do
    context 'with a single key' do
      context 'and key exists' do
        it 'removes the pair from SharedState' do
          described_class.record(42, now)

          Gitlab::Redis::SharedState.with do |redis|
            expect(redis.hscan(described_class::KEY, 0)).to eq(['0', [['42', now.to_i.to_s]]])
          end

          subject.delete(42)

          Gitlab::Redis::SharedState.with do |redis|
            expect(redis.hscan(described_class::KEY, 0)).to eq(['0', []])
          end
        end
      end

      context 'and key does not exist' do
        it 'removes the pair from SharedState' do
          Gitlab::Redis::SharedState.with do |redis|
            expect(redis.hscan(described_class::KEY, 0)).to eq(['0', []])
          end

          subject.delete(42)

          Gitlab::Redis::SharedState.with do |redis|
            expect(redis.hscan(described_class::KEY, 0)).to eq(['0', []])
          end
        end
      end
    end

    context 'with multiple keys' do
      context 'and all keys exist' do
        it 'removes the pair from SharedState' do
          described_class.record(41, now)
          described_class.record(42, now)

          Gitlab::Redis::SharedState.with do |redis|
            expect(redis.hscan(described_class::KEY, 0)).to eq(['0', [['41', now.to_i.to_s], ['42', now.to_i.to_s]]])
          end

          subject.delete(41, 42)

          Gitlab::Redis::SharedState.with do |redis|
            expect(redis.hscan(described_class::KEY, 0)).to eq(['0', []])
          end
        end
      end

      context 'and some keys does not exist' do
        it 'removes the existing pair from SharedState' do
          described_class.record(42, now)

          Gitlab::Redis::SharedState.with do |redis|
            expect(redis.hscan(described_class::KEY, 0)).to eq(['0', [['42', now.to_i.to_s]]])
          end

          subject.delete(41, 42)

          Gitlab::Redis::SharedState.with do |redis|
            expect(redis.hscan(described_class::KEY, 0)).to eq(['0', []])
          end
        end
      end
    end
  end

  describe 'Enumerable' do
    before do
      described_class.record(40, now)
      described_class.record(41, now)
      described_class.record(42, now)
    end

    it 'allows to read the activities sequentially' do
      expected = { '40' => now.to_i.to_s, '41' => now.to_i.to_s, '42' => now.to_i.to_s }

      actual = described_class.new.each_with_object({}) do |(key, time), actual|
        actual[key] = time
      end

      expect(actual).to eq(expected)
    end

    context 'with many records' do
      before do
        1_000.times { |i| described_class.record(i, now) }
      end

      it 'is possible to loop through all the records' do
        expect(described_class.new.count).to eq(1_000)
      end
    end
  end
end
