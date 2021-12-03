# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::SnowplowEnabledMetric do
  using RSpec::Parameterized::TableSyntax

  context 'for snowplow enabled option' do
    where(:snowplow_enabled, :expected_value) do
      true  | true
      false | false
    end

    with_them do
      before do
        stub_application_setting(snowplow_enabled: snowplow_enabled)
      end

      it_behaves_like 'a correct instrumented metric value', { time_frame: 'none' }
    end
  end
end
