# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::MigrationHelpers::WraparoundVacuumHelpers, feature_category: :database do
  include Database::DatabaseHelpers

  let(:table_name) { 'ci_builds' }

  describe '#check_if_wraparound_in_progress' do
    let(:migration) do
      ActiveRecord::Migration.new.extend(described_class)
    end

    subject { migration.check_if_wraparound_in_progress(table_name) }

    it 'delegates to the wraparound class' do
      expect(described_class::WraparoundCheck)
        .to receive(:new)
        .with(table_name, migration: migration)
        .and_call_original

      expect { subject }.not_to raise_error
    end
  end

  describe described_class::WraparoundCheck do
    let(:migration) do
      ActiveRecord::Migration.new.extend(Gitlab::Database::MigrationHelpers::WraparoundVacuumHelpers)
    end

    describe '#execute' do
      subject do
        described_class.new(table_name, migration: migration).execute
      end

      context 'with wraparound vacuuum running' do
        before do
          swapout_view_for_table(:pg_stat_activity, connection: migration.connection, schema: 'pg_temp')

          migration.connection.execute(<<~SQL.squish)
            INSERT INTO pg_stat_activity (
              datid, datname, pid, backend_start, xact_start, query_start,
              state_change, wait_event_type, wait_event, state, backend_xmin,
              query, backend_type)
            VALUES (
              16401, current_database(), 178, '2023-03-30 08:10:50.851322+00',
              '2023-03-30 08:10:50.890485+00', now() - '150 minutes'::interval,
              '2023-03-30 08:10:50.890485+00', 'IO', 'DataFileRead', 'active','3214790381'::xid,
              'autovacuum: VACUUM public.ci_builds (to prevent wraparound)', 'autovacuum worker')
          SQL
        end

        it 'outputs a message related to autovacuum' do
          expect { subject }
            .to output(/Autovacuum with wraparound prevention mode is running on `ci_builds`/).to_stdout
        end

        it { expect { subject }.to output(/autovacuum: VACUUM public.ci_builds \(to prevent wraparound\)/).to_stdout }
        it { expect { subject }.to output(/Current duration: 2 hours, 30 minutes/).to_stdout }

        context 'when GITLAB_MIGRATIONS_DISABLE_WRAPAROUND_CHECK is set' do
          before do
            stub_env('GITLAB_MIGRATIONS_DISABLE_WRAPAROUND_CHECK' => 'true')
          end

          it { expect { subject }.not_to output(/autovacuum/i).to_stdout }

          it 'is disabled on .com' do
            expect(Gitlab).to receive(:com?).and_return(true)

            expect { subject }.not_to raise_error
          end
        end

        context 'when executed by self-managed' do
          before do
            allow(Gitlab).to receive(:com?).and_return(false)
            allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)
          end

          it { expect { subject }.not_to output(/autovacuum/i).to_stdout }
        end
      end

      context 'with wraparound vacuuum not running' do
        it { expect { subject }.not_to output(/autovacuum/i).to_stdout }
      end

      context 'when the table does not exist' do
        let(:table_name) { :no_table }

        it { expect { subject }.to raise_error described_class::WraparoundError, /no_table/ }
      end
    end
  end
end
