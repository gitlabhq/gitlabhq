# frozen_string_literal: true

require 'spec_helper'

describe AlertManagement::UpdateAlertStatusService do
  let_it_be(:alert) { create(:alert_management_alert, status: 'triggered') }

  describe '#execute' do
    subject(:execute) { described_class.new(alert, new_status).execute }

    let(:new_status) { 'acknowledged' }

    it 'updates the status' do
      expect { execute }.to change { alert.acknowledged? }.to(true)
    end

    context 'with unknown status' do
      let(:new_status) { 'random_status' }

      it 'returns an error' do
        expect(execute.status).to eq(:error)
      end

      it 'does not update the status' do
        expect { execute }.not_to change { alert.status }
      end
    end
  end
end
