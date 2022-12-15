# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleRemoveSelfManagedWikiNotes, feature_category: :wiki do
  let!(:batched_migration) { described_class::MIGRATION }

  it 'schedules new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          table_name: :notes,
          column_name: :id,
          interval: described_class::INTERVAL
        )
      }
    end
  end

  context 'with com? or staging?' do
    before do
      allow(::Gitlab).to receive(:com?).and_return(true)
      allow(::Gitlab).to receive(:staging?).and_return(false)
    end

    it 'does not schedule new batched migration' do
      reversible_migration do |migration|
        migration.before -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }

        migration.after -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }
      end
    end
  end
end
