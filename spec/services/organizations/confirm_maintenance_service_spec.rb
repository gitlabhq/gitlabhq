# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::ConfirmMaintenanceService, feature_category: :organization do
  let_it_be_with_reload(:organization) { create(:organization) }
  let(:event) { :confirm_maintenance }
  let(:from_state) { :maintenance_initialization }
  let(:to_state) { :maintenance }
  let(:log_message) { 'Organization maintenance confirmed' }
  let(:invalid_state_message) { 'Organization is not initializing maintenance' }
  let(:fallback_message) { 'Could not confirm maintenance' }

  subject(:response) { described_class.new(organization).execute }

  def stub_ready
    allow_next_instance_of(Gitlab::Organizations::MaintenanceReadiness) do |readiness|
      allow(readiness).to receive(:ready?).and_return(true)
    end
  end

  def reach_source_state
    organization.start_maintenance(maintenance_reason: 'migration')
    stub_ready
  end

  def reach_target_state
    organization.start_maintenance(maintenance_reason: 'migration')
    organization.confirm_maintenance
  end

  def invalid_state_setup
    # active: neither the source nor the target state
  end

  it_behaves_like 'an org_mover maintenance transition service'

  describe '#execute' do
    context 'when the organization is not ready for maintenance' do
      before do
        organization.start_maintenance(maintenance_reason: 'migration')
      end

      it 'returns a retryable error and does not transition', :aggregate_failures do
        expect(response).to be_error
        expect(response.message).to eq('Organization is not ready for maintenance')
        expect(response.reason).to eq(:not_ready)
        expect(organization.reload.state_name).to eq(:maintenance_initialization)
      end
    end
  end
end
