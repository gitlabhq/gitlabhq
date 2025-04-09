# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::EventEligibilityChecker, feature_category: :service_ping do
  using RSpec::Parameterized::TableSyntax

  describe '#eligible?' do
    let(:checker) { described_class.new }

    subject { checker.eligible?(event_name) }

    context 'when fully eligible due to produce usage data' do
      let(:event_name) { 'perform_completion_worker' }

      before do
        create(:application_setting, snowplow_enabled: false, gitlab_product_usage_data_enabled: true)
      end

      it { is_expected.to be(true) }
    end

    context 'for all permutations' do
      where(:event_name, :product_usage_data_enabled, :snowplow_enabled, :result) do
        'perform_completion_worker' | true | false | true
        'perform_completion_worker' | false | false | true
        'some_other_event' | true | false | true
        'some_other_event' | false | true | true
        'some_other_event' | false | false | false
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

    context 'when collect_product_usage_events feature flag is disabled' do
      where(:event_name, :product_usage_data_enabled, :snowplow_enabled, :result) do
        'perform_completion_worker' | true  | false | false
        'perform_completion_worker' | false | false | false
        'some_other_event'          | true  | false | false
        'some_other_event'          | false | true  | true
        'some_other_event'          | false | false | false
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
