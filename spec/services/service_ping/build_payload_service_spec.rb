# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServicePing::BuildPayloadService do
  describe '#execute', :without_license do
    subject(:service_ping_payload) { described_class.new.execute }

    include_context 'stubbed service ping metrics definitions' do
      let(:subscription_metrics) do
        [
          metric_attributes('active_user_count', "Subscription")
        ]
      end
    end

    context 'when usage_ping_enabled setting is false' do
      before do
        # Gitlab::CurrentSettings.usage_ping_enabled? == false
        stub_config_setting(usage_ping_enabled: false)
      end

      it 'returns empty service ping payload' do
        expect(service_ping_payload).to eq({})
      end
    end

    context 'when usage_ping_enabled setting is true' do
      before do
        # Gitlab::CurrentSettings.usage_ping_enabled? == true
        stub_config_setting(usage_ping_enabled: true)
      end

      it_behaves_like 'complete service ping payload'

      context 'with require stats consent enabled' do
        before do
          allow(User).to receive(:single_user).and_return(double(:user, requires_usage_stats_consent?: true))
        end

        it 'returns empty service ping payload' do
          expect(service_ping_payload).to eq({})
        end
      end
    end
  end
end
