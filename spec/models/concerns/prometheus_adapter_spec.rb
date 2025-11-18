# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PrometheusAdapter, feature_category: :integrations do
  # Temporary dummy class to test PrometheusAdapter independently.
  # The original PrometheusIntegration class has been removed, but we keep
  # this spec to ensure the concern itself is still covered. The adapter
  # classes (and their specs) will be fully removed in a follow-up MR.
  let(:integration) do
    Class.new do
      include PrometheusAdapter
    end.new
  end

  describe '#build_query_args' do
    subject { integration.build_query_args(*args) }

    context 'when active record models are included' do
      let(:args) { [double(:environment, id: 12)] }

      it 'serializes by id' do
        is_expected.to eq [12]
      end
    end

    context 'when args are safe for serialization' do
      let(:args) { ['stringy arg', 5, 6.0, :symbolic_arg] }

      it 'does nothing' do
        is_expected.to eq args
      end
    end
  end
end
