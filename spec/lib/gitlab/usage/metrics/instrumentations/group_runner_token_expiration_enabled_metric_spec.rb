# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::GroupRunnerTokenExpirationEnabledMetric, feature_category: :runner do
  using RSpec::Parameterized::TableSyntax

  context 'for group runner authentication token expiration option' do
    let_it_be(:namespace_settings) { create(:namespace_settings) }
    let_it_be(:group) { create(:group, namespace_settings: namespace_settings) }

    where(:application_setting, :namespace_setting, :expected_value) do
      nil | nil  | false
      0.0 | nil  | false
      nil | 0.0  | false
      1.0 | nil  | true
      nil | 1.0  | true
      1.0 | 1.0  | true
    end

    with_them do
      before do
        stub_application_setting(group_runner_token_expiration_interval: application_setting)
        namespace_settings.update!(subgroup_runner_token_expiration_interval: namespace_setting)
      end

      it_behaves_like 'a correct instrumented metric value', { time_frame: 'none' }
    end
  end
end
