# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Middleware::SidekiqShardAwarenessValidation, feature_category: :scalability do
  let(:app) { ->(_env) { Sidekiq.redis(&:ping) } }
  let(:env) { {} }

  around do |example|
    original_state = Thread.current[:validate_sidekiq_shard_awareness]
    Thread.current[:validate_sidekiq_shard_awareness] = nil

    example.run

    Thread.current[:validate_sidekiq_shard_awareness] = original_state
  end

  describe '#call' do
    subject(:app_call) { described_class.new(app).call(env) }

    it 'enables shard-awareness check within the context of a request' do
      expect { Sidekiq.redis(&:ping) }.not_to raise_error
      expect { app_call }.to raise_error(Gitlab::SidekiqSharding::Validator::UnroutedSidekiqApiError)
    end
  end
end
