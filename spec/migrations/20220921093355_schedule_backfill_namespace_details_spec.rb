# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleBackfillNamespaceDetails, schema: 20220921093355, feature_category: :subgroups do
  context 'when on gitlab.com' do
    let(:background_migration) { described_class::MIGRATION }
    let(:migration) { described_class.new }

    before do
      migration.up
    end

    describe '#up' do
      it 'schedules background jobs for each batch of projects' do
        expect(background_migration).to(
          have_scheduled_batched_migration(
            table_name: :namespaces,
            column_name: :id,
            interval: described_class::INTERVAL,
            batch_size: described_class::BATCH_SIZE,
            sub_batch_size: described_class::SUB_BATCH_SIZE
          )
        )
      end
    end

    describe '#down' do
      it 'deletes all batched migration records' do
        migration.down

        expect(described_class::MIGRATION).not_to have_scheduled_batched_migration
      end
    end
  end
end
