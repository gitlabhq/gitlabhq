# frozen_string_literal: true

require 'spec_helper'

describe AlertManagement::AlertPolicy, :models do
  let(:alert) { create(:alert_management_alert) }
  let(:project) { alert.project }
  let(:user) { create(:user) }
  let(:policy) { described_class.new(user, alert) }

  describe 'rules' do
    it { expect(policy).to be_disallowed :read_alert_management_alerts }

    context 'when developer' do
      before do
        project.add_developer(user)
      end

      it { expect(policy).to be_allowed :read_alert_management_alerts }
    end
  end
end
