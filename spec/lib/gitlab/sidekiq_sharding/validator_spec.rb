# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqSharding::Validator, feature_category: :scalability do
  subject(:ping) { Sidekiq.redis(&:ping) }

  before do
    Thread.current[:inside_sidekiq_via_scope] = nil
    Thread.current[:allow_unrouted_sidekiq_calls] = nil
  end

  describe '.via' do
    it 'sets Thread.current within via' do
      expect(Gitlab::ErrorTracking).not_to receive(:track_and_raise_for_dev_exception)

      Sidekiq::Client.via(Gitlab::Redis::Queues.sidekiq_redis) do
        expect(Thread.current[:inside_sidekiq_via_scope]).to be_truthy

        ping
      end
    end

    it 'restores Thread.current inside_sidekiq_via_scope value after exiting scope' do
      Thread.current[:inside_sidekiq_via_scope] = 'test'

      Sidekiq::Client.via(Gitlab::Redis::Queues.sidekiq_redis) do
        expect(Thread.current[:inside_sidekiq_via_scope]).to be_truthy
      end

      expect(Thread.current[:inside_sidekiq_via_scope]).to eq('test')
    end
  end

  describe '#method_missing' do
    using RSpec::Parameterized::TableSyntax
    # we test method_missing through .ping

    where(:env, :expected_error) do
      'production'  | nil
      'test'        | described_class::UnroutedSidekiqApiError
      'development' | described_class::UnroutedSidekiqApiError
    end

    with_them do
      before do
        stub_rails_env(env)
      end

      it do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).and_call_original

        if expected_error
          expect { ping }.to raise_error(expected_error)
        else
          expect { ping }.not_to raise_error
        end
      end
    end
  end

  describe '.allow_unrouted_sidekiq_calls' do
    it 'permits unrouted calls' do
      expect(Gitlab::ErrorTracking).not_to receive(:track_and_raise_for_dev_exception)

      described_class.allow_unrouted_sidekiq_calls do
        expect(Thread.current[:inside_sidekiq_via_scope]).to be_falsey
        expect(Thread.current[:allow_unrouted_sidekiq_calls]).to be_truthy

        ping
      end
    end

    it 'restores Thread.current allow_unrouted_sidekiq_calls value after exiting scope' do
      Thread.current[:allow_unrouted_sidekiq_calls] = 'test'

      described_class.allow_unrouted_sidekiq_calls do
        expect(Thread.current[:allow_unrouted_sidekiq_calls]).to be_truthy
      end

      expect(Thread.current[:allow_unrouted_sidekiq_calls]).to eq('test')
    end
  end

  describe '.enabled' do
    around do |example|
      original_state = Thread.current[:validate_sidekiq_shard_awareness]
      Thread.current[:validate_sidekiq_shard_awareness] = nil

      example.run

      Thread.current[:validate_sidekiq_shard_awareness] = original_state
    end

    it 'scopes validation to within the block' do
      # avoid reusing subject due to memoized behaviours. subject should be called once only.
      expect { Sidekiq.redis(&:ping) }.not_to raise_error

      described_class.enabled do
        expect { ping }.to raise_error(described_class::UnroutedSidekiqApiError)
      end
    end

    it 'restores Thread.current validate_sidekiq_shard_awareness value after exiting scope' do
      Thread.current[:validate_sidekiq_shard_awareness] = 'test'

      described_class.enabled do
        expect(Thread.current[:validate_sidekiq_shard_awareness]).to be_truthy
      end

      expect(Thread.current[:validate_sidekiq_shard_awareness]).to eq('test')
    end
  end
end
