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
      stub_application_setting(snowplow_enabled: snowplow_enabled)
      allow(Gitlab::Usage::ProductUsageDataSetting).to receive(:enabled?).and_return(product_usage_data_enabled)
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
      stub_application_setting(snowplow_enabled: snowplow_enabled)
      allow(Gitlab::Usage::ProductUsageDataSetting).to receive(:enabled?).and_return(product_usage_data_enabled)
    end

    with_them do
      it { is_expected.to eq(result) }
    end
  end

  describe '.send_frontend_events?' do
    subject { described_class.send_frontend_events? }

    where(:product_usage_data_enabled, :snowplow_enabled) do
      true  | true
      true  | false
      false | true
    end

    with_them do
      before do
        stub_application_setting(snowplow_enabled: snowplow_enabled)
        allow(Gitlab::Usage::ProductUsageDataSetting).to receive(:enabled?).and_return(product_usage_data_enabled)
      end

      it { is_expected.to be(true) }
    end

    context 'when Snowplow and product usage data are disabled' do
      before do
        stub_application_setting(snowplow_enabled: false)
        allow(Gitlab::Usage::ProductUsageDataSetting).to receive(:enabled?).and_return(false)
      end

      it 'returns false', unless: Gitlab.ee? do
        is_expected.to be(false)
      end
    end
  end
end
