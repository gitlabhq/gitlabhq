# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::ExitMaintenanceService, feature_category: :organization do
  let_it_be_with_reload(:organization) { create(:organization) }
  let(:event) { :exit_maintenance }
  let(:from_state) { :maintenance }
  let(:to_state) { :active }
  let(:log_message) { 'Organization maintenance exited' }
  let(:invalid_state_message) { 'Organization is not in maintenance' }
  let(:fallback_message) { 'Could not exit maintenance' }

  subject(:response) { described_class.new(organization).execute }

  def reach_source_state
    organization.start_maintenance(maintenance_reason: 'migration')
    organization.confirm_maintenance
  end

  def reach_target_state
    # already active by default
  end

  def invalid_state_setup
    organization.start_maintenance(maintenance_reason: 'migration')
  end

  it_behaves_like 'an org_mover maintenance transition service'
end
