# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServicePing::ServicePingSettings do
  using RSpec::Parameterized::TableSyntax

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
        expect(described_class.product_intelligence_enabled?).to eq(expected_product_intelligence_enabled)
      end
    end
  end
end
