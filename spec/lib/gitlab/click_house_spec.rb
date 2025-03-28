# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ClickHouse, feature_category: :database do
  subject { described_class }

  context 'when ClickHouse is not configured' do
    it { is_expected.not_to be_configured }

    it { is_expected.not_to be_enabled_for_analytics }

    it { is_expected.not_to be_globally_enabled_for_analytics }

    context 'and is enabled for analytics on settings' do
      before do
        stub_application_setting(use_clickhouse_for_analytics: true)
      end

      it { is_expected.not_to be_enabled_for_analytics }

      it { is_expected.not_to be_globally_enabled_for_analytics }
    end
  end

  context 'when ClickHouse is configured', :click_house do
    it { is_expected.to be_configured }

    it { is_expected.not_to be_enabled_for_analytics }

    it { is_expected.not_to be_globally_enabled_for_analytics }

    context 'and enabled for analytics on settings' do
      before do
        stub_application_setting(use_clickhouse_for_analytics: true)
      end

      it { is_expected.to be_enabled_for_analytics }

      it { is_expected.to be_globally_enabled_for_analytics }
    end
  end
end
