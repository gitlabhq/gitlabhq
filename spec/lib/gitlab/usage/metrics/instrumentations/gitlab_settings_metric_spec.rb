# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::GitlabSettingsMetric, feature_category: :service_ping do
  describe 'settings metric' do
    using RSpec::Parameterized::TableSyntax

    where(:setting_value, :expected_value) do
      false | false
      true  | true
    end

    with_them do
      before do
        stub_application_setting(gravatar_enabled: setting_value)
      end

      it_behaves_like 'a correct instrumented metric value', {
        time_frame: 'none',
        options: {
          setting_method: 'gravatar_enabled'
        }
      }
    end
  end
end
