# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleDeleteOrphanedOperationalVulnerabilities, feature_category: :vulnerability_management do
  let!(:migration) { described_class.new }
  let!(:post_migration) { described_class::MIGRATION }

  describe '#up' do
    it 'schedules background jobs for each batch of vulnerabilities' do
      migration.up

      expect(post_migration).to(
        have_scheduled_batched_migration(
          table_name: :vulnerabilities,
          column_name: :id,
          interval: described_class::INTERVAL,
          batch_size: described_class::BATCH_SIZE
        )
      )
    end
  end

  describe '#down' do
    it 'deletes all batched migration records' do
      migration.down

      expect(post_migration).not_to have_scheduled_batched_migration
    end
  end
end
