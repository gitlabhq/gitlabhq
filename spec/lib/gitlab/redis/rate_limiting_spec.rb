# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::RateLimiting do
  include_examples "redis_new_instance_shared_examples", 'rate_limiting', Gitlab::Redis::Cache

  describe '.cache_store' do
    context 'when encountering an error' do
      subject { described_class.cache_store.read('x') }

      before do
        described_class.with do |redis|
          allow(redis).to receive(:get).and_raise(::Redis::CommandError)
        end
      end

      it 'logs error' do
        expect(::Gitlab::ErrorTracking).to receive(:log_exception)
        subject
      end
    end
  end
end
