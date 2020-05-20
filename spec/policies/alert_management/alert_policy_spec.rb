# frozen_string_literal: true

require 'spec_helper'

describe AlertManagement::AlertPolicy, :models do
  let(:alert) { create(:alert_management_alert) }
  let(:project) { alert.project }
  let(:user) { create(:user) }

  subject(:policy) { described_class.new(user, alert) }

  describe 'rules' do
    it { is_expected.to be_disallowed :read_alert_management_alert }
    it { is_expected.to be_disallowed :update_alert_management_alert }

    context 'when developer' do
      before do
        project.add_developer(user)
      end

      it { is_expected.to be_allowed :read_alert_management_alert }
      it { is_expected.to be_allowed :update_alert_management_alert }
    end
  end
end
