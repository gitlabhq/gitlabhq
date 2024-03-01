# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeBackfillResourceLinkEvents, feature_category: :team_planning do
  let(:batched_migrations) { table(:batched_background_migrations) }

  context 'when migration is missing' do
    before do
      batched_migrations.where(job_class_name: described_class::MIGRATION).delete_all
    end

    it 'warns migration not found' do
      expect(Gitlab::AppLogger)
        .to receive(:warn).with(/Could not find batched background migration for the given configuration:/)
                          .once

      migrate!
    end
  end

  context 'with migration present' do
    let!(:batched_migration) do
      batched_migrations.create!(
        job_class_name: described_class::MIGRATION,
        table_name: :system_note_metadata,
        column_name: :id,
        interval: 2.minutes,
        min_value: 1,
        max_value: 5,
        batch_size: 5,
        sub_batch_size: 5,
        gitlab_schema: :gitlab_main,
        status: status
      )
    end

    context 'when migrations have finished' do
      let(:status) { 3 } # finished enum value

      it 'does not raise an error' do
        expect { migrate! }.not_to raise_error
      end
    end

    context 'with different migration statuses' do
      using RSpec::Parameterized::TableSyntax

      where(:status, :description) do
        0 | 'paused'
        1 | 'active'
        4 | 'failed'
        5 | 'finalizing'
      end

      with_them do
        it 'finalizes the migration' do
          expect do
            migrate!

            batched_migration.reload
          end.to change { batched_migration.status }.from(status).to(6)
        end
      end
    end
  end
end
