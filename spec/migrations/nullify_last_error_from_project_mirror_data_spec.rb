# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe NullifyLastErrorFromProjectMirrorData, feature_category: :source_code_management do
  let(:migration) { described_class::MIGRATION }

  before do
    migrate!
  end

  describe '#up' do
    it 'schedules background jobs for each batch of projects' do
      expect(migration).to(
        have_scheduled_batched_migration(
          table_name: :project_mirror_data,
          column_name: :id,
          interval: described_class::INTERVAL,
          batch_size: described_class::BATCH_SIZE,
          sub_batch_size: described_class::SUB_BATCH_SIZE
        )
      )
    end
  end

  describe '#down' do
    before do
      schema_migrate_down!
    end

    it 'deletes all batched migration records' do
      expect(migration).not_to have_scheduled_batched_migration
    end
  end
end
