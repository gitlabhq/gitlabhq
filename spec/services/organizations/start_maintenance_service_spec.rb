# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::StartMaintenanceService, feature_category: :organization do
  let_it_be_with_reload(:organization) { create(:organization) }
  let(:event) { :start_maintenance }
  let(:from_state) { :active }
  let(:to_state) { :maintenance_initialization }
  let(:log_message) { 'Organization maintenance started' }
  let(:invalid_state_message) { 'Organization is not active' }
  let(:fallback_message) { 'Could not start maintenance' }

  let(:maintenance_reason) { 'migration' }

  subject(:response) { described_class.new(organization, maintenance_reason: maintenance_reason).execute }

  def reach_source_state
    # already active by default
  end

  def reach_target_state
    organization.start_maintenance(maintenance_reason: 'migration')
  end

  def invalid_state_setup
    organization.start_maintenance(maintenance_reason: 'migration')
    organization.confirm_maintenance
  end

  it_behaves_like 'an org_mover maintenance transition service'

  describe '#execute' do
    context 'when the maintenance_reason is invalid' do
      let(:maintenance_reason) { 'not-a-reason' }

      it 'returns an error and does not transition', :aggregate_failures do
        expect(response).to be_error
        expect(organization.reload.state_name).to eq(:active)
      end
    end

    context 'when the organization is the default organization' do
      # rubocop:disable Gitlab/RSpec/AvoidCreateDefaultOrganization -- required for testing default organization guard
      let_it_be_with_reload(:organization) { create(:organization, :default) }
      # rubocop:enable Gitlab/RSpec/AvoidCreateDefaultOrganization

      it 'returns an error, because maintenance is blocked for the default org', :aggregate_failures do
        expect(response).to be_error
        expect(organization.reload.state_name).to eq(:active)
      end
    end
  end
end
