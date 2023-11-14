# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::GitlabConfigMetric, feature_category: :service_ping do
  describe 'config metric' do
    using RSpec::Parameterized::TableSyntax

    where(:config_value, :expected_value) do
      false | false
      true  | true
    end

    with_them do
      before do
        stub_config(artifacts: { object_store: { enabled: config_value } })
      end

      it_behaves_like 'a correct instrumented metric value', {
        time_frame: 'none',
        options: {
          config: {
            artifacts: {
              object_store: 'enabled'
            }
          }
        }
      }
    end
  end
end
