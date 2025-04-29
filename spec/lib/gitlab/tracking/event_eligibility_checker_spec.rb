# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::EventEligibilityChecker, feature_category: :service_ping do
  using RSpec::Parameterized::TableSyntax

  describe '#eligible?' do
    let(:checker) { described_class.new }
    let(:event_name) { 'event_name' }

    subject { checker.eligible?(event_name) }

    context 'when collect_product_usage_events feature flag is enabled' do
      where(:product_usage_data_enabled, :snowplow_enabled, :result) do
        true | false | true
        false | true | true
        false | false | false
      end

      before do
        stub_application_setting(
          snowplow_enabled: snowplow_enabled,
          gitlab_product_usage_data_enabled?: product_usage_data_enabled
        )
      end

      with_them do
        it { is_expected.to eq(result) }
      end
    end

    context 'when collect_product_usage_events feature flag is disabled' do
      where(:product_usage_data_enabled, :snowplow_enabled, :result) do
        true  | false | false
        false | true  | true
        false | false | false
      end

      before do
        stub_feature_flags(collect_product_usage_events: false)
        stub_application_setting(
          snowplow_enabled?: snowplow_enabled, gitlab_product_usage_data_enabled?: product_usage_data_enabled
        )
      end

      with_them do
        it { is_expected.to eq(result) }
      end
    end
  end
end
