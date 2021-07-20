# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServicePing::PermitDataCategoriesService do
  using RSpec::Parameterized::TableSyntax

  describe '#execute', :without_license do
    subject(:permitted_categories) { described_class.new.execute }

    context 'when usage ping setting is set to true' do
      before do
        allow(User).to receive(:single_user).and_return(double(:user, requires_usage_stats_consent?: false))
        stub_config_setting(usage_ping_enabled: true)
      end

      it 'returns all categories' do
        expect(permitted_categories).to match_array(%w[Standard Subscription Operational Optional])
      end
    end

    context 'when usage ping setting is set to false' do
      before do
        allow(User).to receive(:single_user).and_return(double(:user, requires_usage_stats_consent?: false))
        stub_config_setting(usage_ping_enabled: false)
      end

      it 'returns no categories' do
        expect(permitted_categories).to match_array([])
      end
    end

    context 'when User.single_user&.requires_usage_stats_consent? is required' do
      before do
        allow(User).to receive(:single_user).and_return(double(:user, requires_usage_stats_consent?: true))
        stub_config_setting(usage_ping_enabled: true)
      end

      it 'returns no categories' do
        expect(permitted_categories).to match_array([])
      end
    end
  end

  describe '#product_intelligence_enabled?' do
    where(:usage_ping_enabled, :requires_usage_stats_consent, :expected_product_intelligence_enabled) do
      # Usage ping enabled
      true  | false | true
      true  | true  | false

      # Usage ping disabled
      false | false | false
      false | true  | false
    end

    with_them do
      before do
        allow(User).to receive(:single_user).and_return(double(:user, requires_usage_stats_consent?: requires_usage_stats_consent))
        stub_config_setting(usage_ping_enabled: usage_ping_enabled)
      end

      it 'has the correct product_intelligence_enabled?' do
        expect(described_class.new.product_intelligence_enabled?).to eq(expected_product_intelligence_enabled)
      end
    end
  end
end
