# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::EventEligibilityChecker, feature_category: :service_ping do
  using RSpec::Parameterized::TableSyntax

  let(:checker) { described_class.new }

  describe '#eligible?' do
    let(:event_name) { 'event_name' }

    subject { checker.eligible?(event_name) }

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

  describe '#only_send_duo_events?' do
    subject { described_class.only_send_duo_events? }

    where(:product_usage_data_enabled, :snowplow_enabled, :result) do
      true  | true  | false
      true  | false | false
      false | true  | false
      false | false | true
    end

    before do
      stub_application_setting(
        snowplow_enabled?: snowplow_enabled, gitlab_product_usage_data_enabled?: product_usage_data_enabled
      )
    end

    with_them do
      it { is_expected.to eq(result) }
    end
  end
end
