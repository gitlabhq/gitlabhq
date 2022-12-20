# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleBackfillProjectSettings, feature_category: :projects do
  let!(:migration) { described_class::MIGRATION }

  describe '#up' do
    it 'schedules background jobs for each batch of projects' do
      migrate!

      expect(migration).to(
        have_scheduled_batched_migration(
          table_name: :projects,
          column_name: :id,
          interval: described_class::INTERVAL
        )
      )
    end
  end
end
