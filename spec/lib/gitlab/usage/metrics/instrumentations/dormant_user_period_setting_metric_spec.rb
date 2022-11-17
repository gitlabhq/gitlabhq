# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::DormantUserPeriodSettingMetric do
  using RSpec::Parameterized::TableSyntax

  where(:deactivate_dormant_users_period_value, :expected_value) do
    90   | 90 # default
    365  | 365
  end

  with_them do
    before do
      stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
      stub_application_setting(deactivate_dormant_users_period: deactivate_dormant_users_period_value)
    end

    it_behaves_like 'a correct instrumented metric value', {}
  end
end
