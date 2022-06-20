# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServicePing::PermitDataCategories do
  describe '#execute', :without_license do
    subject(:permitted_categories) { described_class.new.execute }

    context 'when usage ping setting is set to true' do
      before do
        allow(User).to receive(:single_user)
          .and_return(instance_double(User, :user, requires_usage_stats_consent?: false))
        stub_config_setting(usage_ping_enabled: true)
      end

      it 'returns all categories' do
        expect(permitted_categories).to match_array(%w[standard subscription operational optional])
      end
    end

    context 'when usage ping setting is set to false' do
      it 'returns all categories' do
        stub_config_setting(usage_ping_enabled: false)

        expect(permitted_categories).to match_array(%w[standard subscription operational optional])
      end
    end
  end
end
