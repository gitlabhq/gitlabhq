# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GrapeLogging::Loggers::PerfLogger do
  subject { described_class.new }

  describe ".parameters" do
    let(:mock_request) { OpenStruct.new(env: {}) }

    describe 'when no performance datais are present' do
      it 'returns an empty Hash' do
        expect(subject.parameters(mock_request, nil)).to eq({})
      end
    end

    describe 'when Redis calls are present', :request_store do
      it 'returns a Hash with Redis information' do
        Gitlab::Redis::SharedState.with { |redis| redis.get('perf-logger-test') }

        payload = subject.parameters(mock_request, nil)

        expect(payload[:redis_calls]).to eq(1)
        expect(payload[:redis_duration_s]).to be >= 0
      end
    end
  end
end
