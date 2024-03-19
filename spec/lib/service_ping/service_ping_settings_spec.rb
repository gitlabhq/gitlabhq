# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServicePing::ServicePingSettings do
  using RSpec::Parameterized::TableSyntax

  describe '#enabled_and_consented?' do
    where(:usage_ping_enabled, :requires_usage_stats_consent, :expected_enabled_and_consented) do
      # Usage ping enabled
      true  | false | true
      true  | true  | false

      # Usage ping disabled
      false | false | false
      false | true  | false
    end

    with_them do
      before do
        allow(User).to receive(:single_user)
          .and_return(instance_double(User, :user, requires_usage_stats_consent?: requires_usage_stats_consent))
        stub_config_setting(usage_ping_enabled: usage_ping_enabled)
      end

      it 'has the correct enabled_and_consented?' do
        expect(described_class.enabled_and_consented?).to eq(expected_enabled_and_consented)
      end
    end
  end

  describe '#license_operational_metric_enabled?' do
    it 'returns false' do
      expect(described_class.license_operational_metric_enabled?).to eq(false)
    end
  end

  describe '#enabled?' do
    describe 'has the correct enabled' do
      it 'when false' do
        stub_config_setting(usage_ping_enabled: false)

        expect(described_class.enabled?).to eq(false)
      end

      it 'when true' do
        stub_config_setting(usage_ping_enabled: true)

        expect(described_class.enabled?).to eq(true)
      end
    end
  end
end
