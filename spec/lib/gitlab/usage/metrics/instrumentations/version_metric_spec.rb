# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../../support/shared_examples/metrics_instrumentation_shared_examples'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::VersionMetric, feature_category: :service_ping do
  let(:expected_value) { Gitlab::VERSION }

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', data_source: 'database' }
end
