# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountCiRunnersInstanceTypeActiveOnlineMetric, feature_category: :runner do
  let(:expected_value) { 1 }

  before do
    create(:ci_runner, :online)
  end

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', data_source: 'database' }
end
