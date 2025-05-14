# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::AkismetEnabledMetric, feature_category: :service_ping do
  before do
    allow(Gitlab::CurrentSettings).to receive(:akismet_enabled).and_return(expected_value)
  end

  context 'when akismet is enabled' do
    let(:expected_value) { true }

    it_behaves_like 'a correct instrumented metric value', { time_frame: 'none' }
  end

  context 'when akismet is disabled' do
    let(:expected_value) { false }

    it_behaves_like 'a correct instrumented metric value', { time_frame: 'none' }
  end
end
