# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::SpamcheckEnabledMetric, feature_category: :service_ping do
  before do
    allow(Gitlab::CurrentSettings).to receive(:spam_check_endpoint_enabled).and_return(expected_value)
  end

  context 'when spamcheck is enabled' do
    let(:expected_value) { true }

    it_behaves_like 'a correct instrumented metric value', { time_frame: 'none' }
  end

  context 'when spamcheck is disabled' do
    let(:expected_value) { false }

    it_behaves_like 'a correct instrumented metric value', { time_frame: 'none' }
  end
end
