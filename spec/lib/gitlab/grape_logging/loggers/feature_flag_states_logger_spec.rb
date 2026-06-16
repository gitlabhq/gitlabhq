# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GrapeLogging::Loggers::FeatureFlagStatesLogger, feature_category: :feature_flags do
  let(:request) { instance_double(Rack::Request) }

  subject(:parameters) { described_class.new.parameters(request, nil) }

  describe '#parameters' do
    context 'when feature_flag_state_logs is enabled' do
      before do
        stub_feature_flags(feature_flag_state_logs: true)
      end

      it 'returns the logged feature flag states' do
        allow(Feature).to receive(:logged_states_for_log).and_return(['some_flag:1', 'other_flag:0'])

        expect(parameters).to eq(feature_flag_states: ['some_flag:1', 'other_flag:0'])
      end

      it 'returns an empty hash when no states were logged' do
        allow(Feature).to receive(:logged_states_for_log).and_return([])

        expect(parameters).to eq({})
      end
    end

    context 'when feature_flag_state_logs is disabled' do
      before do
        stub_feature_flags(feature_flag_state_logs: false)
      end

      it 'returns an empty hash' do
        expect(Feature).not_to receive(:logged_states_for_log)

        expect(parameters).to eq({})
      end
    end
  end
end
