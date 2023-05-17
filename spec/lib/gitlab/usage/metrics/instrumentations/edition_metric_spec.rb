# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::EditionMetric, feature_category: :service_ping do
  before do
    allow(Gitlab).to receive(:ee?).and_return(false)
  end

  let(:expected_value) { 'CE' }

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'all' }
end
