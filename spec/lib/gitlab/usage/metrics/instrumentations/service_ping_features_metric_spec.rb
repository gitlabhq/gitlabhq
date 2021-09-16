# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::ServicePingFeaturesMetric do
  using RSpec::Parameterized::TableSyntax

  where(:usage_ping_features_enabled, :expected_value) do
    true  | true
    false | false
  end

  with_them do
    before do
      stub_application_setting(usage_ping_features_enabled: usage_ping_features_enabled)
    end

    it_behaves_like 'a correct instrumented metric value', { time_frame: 'none' }
  end
end
