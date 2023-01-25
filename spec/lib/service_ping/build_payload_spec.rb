# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServicePing::BuildPayload, feature_category: :service_ping do
  describe '#execute', :without_license do
    subject(:service_ping_payload) { described_class.new.execute }

    include_context 'stubbed service ping metrics definitions' do
      let(:subscription_metrics) do
        [
          metric_attributes('active_user_count', "subscription")
        ]
      end
    end

    it_behaves_like 'complete service ping payload'
  end
end
