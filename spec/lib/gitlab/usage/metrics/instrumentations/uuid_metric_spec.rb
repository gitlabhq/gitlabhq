# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::UuidMetric do
  let(:expected_value) { Gitlab::CurrentSettings.uuid }

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'none' }
end
