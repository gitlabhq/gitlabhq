# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::HttpIntegrationPolicy, :models do
  let(:integration) { create(:alert_management_http_integration) }
  let(:project) { integration.project }
  let(:user) { create(:user) }

  subject(:policy) { described_class.new(user, integration) }

  describe 'rules' do
    it { is_expected.to be_disallowed :admin_operations }

    context 'when maintainer' do
      before do
        project.add_maintainer(user)
      end

      it { is_expected.to be_allowed :admin_operations }
    end
  end
end
