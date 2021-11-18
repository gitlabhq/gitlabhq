# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GrapeLogging::Loggers::PerfLogger do
  let(:mock_request) { double('env', env: {}) }

  describe ".parameters" do
    subject { described_class.new.parameters(mock_request, nil) }

    let(:perf_data) { { redis_calls: 1 } }

    describe 'when no performance data present' do
      it { is_expected.not_to include(perf_data) }
    end

    describe 'when performance data present', :request_store do
      before do
        Gitlab::Redis::SharedState.with { |redis| redis.get('perf-logger-test') }
      end

      it { is_expected.to include(perf_data) }
    end
  end
end
