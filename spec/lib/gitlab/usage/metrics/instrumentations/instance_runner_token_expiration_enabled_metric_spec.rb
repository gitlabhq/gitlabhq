# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::InstanceRunnerTokenExpirationEnabledMetric, feature_category: :runner do
  using RSpec::Parameterized::TableSyntax

  context 'for instance runner authentication token expiration option' do
    where(:application_setting, :expected_value) do
      nil | false
      0.0 | false
      1.0 | true
    end

    with_them do
      before do
        stub_application_setting(runner_token_expiration_interval: application_setting)
      end

      it_behaves_like 'a correct instrumented metric value', { time_frame: 'none' }
    end
  end
end
