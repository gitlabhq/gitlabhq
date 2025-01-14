# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::SnowplowConfiguredToGitlabCollectorMetric do
  using RSpec::Parameterized::TableSyntax

  context 'for collector_hostname option' do
    where(:collector_hostname, :expected_value) do
      'snowplowprd.trx.gitlab.net' | true
      'foo.bar.something.net'      | false
    end

    with_them do
      before do
        stub_application_setting(snowplow_collector_hostname: collector_hostname)
      end

      it_behaves_like 'a correct instrumented metric value', { time_frame: 'none' }
    end
  end
end
