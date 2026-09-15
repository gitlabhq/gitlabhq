# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::CancelMaintenanceService, feature_category: :organization do
  let_it_be_with_reload(:organization) { create(:organization) }
  let(:event) { :cancel_maintenance }
  let(:from_state) { :maintenance_initialization }
  let(:to_state) { :active }
  let(:log_message) { 'Organization maintenance cancelled' }
  let(:invalid_state_message) { 'Organization is not initializing maintenance' }
  let(:fallback_message) { 'Could not cancel maintenance' }

  subject(:response) { described_class.new(organization).execute }

  def reach_source_state
    organization.start_maintenance(maintenance_reason: 'migration')
  end

  def reach_target_state
    # already active by default
  end

  def invalid_state_setup
    organization.start_maintenance(maintenance_reason: 'migration')
    organization.confirm_maintenance
  end

  it_behaves_like 'an org_mover maintenance transition service'
end
