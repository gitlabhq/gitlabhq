# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::RunnerRegistrationTokensAllowedMetric, feature_category: :runner do
  using RSpec::Parameterized::TableSyntax

  context 'for runner registration tokens enabled option' do
    where(:allow_runner_registration_token, :expected_value) do
      true  | true
      false | false
    end

    with_them do
      before do
        stub_application_setting(allow_runner_registration_token: allow_runner_registration_token)
      end

      it_behaves_like 'a correct instrumented metric value', { time_frame: 'none' }
    end
  end
end
