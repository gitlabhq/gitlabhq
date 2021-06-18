# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IntegrationPolicy, :models do
  let_it_be(:user) { create(:user) }

  let(:project) { integration.project }

  subject(:policy) { Ability.policy_for(user, integration) }

  context 'when the integration is a prometheus_integration' do
    let(:integration) { create(:prometheus_integration) }

    describe 'rules' do
      it { is_expected.to be_disallowed :admin_project }

      context 'when maintainer' do
        before do
          project.add_maintainer(user)
        end

        it { is_expected.to be_allowed :admin_project }
      end
    end
  end
end
