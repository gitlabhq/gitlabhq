# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveScheduleAndStatusFromPendingAlertEscalations, feature_category: :incident_management do
  let(:escalations) { table(:incident_management_pending_alert_escalations) }
  let(:schedule_index) { 'index_incident_management_pending_alert_escalations_on_schedule' }
  let(:schedule_foreign_key) { 'fk_rails_fcbfd9338b' }

  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(escalations.column_names).to include('schedule_id', 'status')
        expect(escalations_indexes).to include(schedule_index)
        expect(escalations_constraints).to include(schedule_foreign_key)
      }

      migration.after -> {
        escalations.reset_column_information
        expect(escalations.column_names).not_to include('schedule_id', 'status')
        expect(escalations_indexes).not_to include(schedule_index)
        expect(escalations_constraints).not_to include(schedule_foreign_key)
      }
    end
  end

  private

  def escalations_indexes
    ActiveRecord::Base.connection.indexes(:incident_management_pending_alert_escalations).collect(&:name)
  end

  def escalations_constraints
    ActiveRecord::Base.connection.foreign_keys(:incident_management_pending_alert_escalations).collect(&:name)
  end
end
