# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::DormantUserSettingEnabledMetric do
  using RSpec::Parameterized::TableSyntax

  where(:deactivate_dormant_users_enabled, :expected_value) do
    1 | 1
    0 | 0
  end

  with_them do
    before do
      stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
      stub_application_setting(deactivate_dormant_users: deactivate_dormant_users_enabled)
    end

    it_behaves_like 'a correct instrumented metric value', {}
  end
end
