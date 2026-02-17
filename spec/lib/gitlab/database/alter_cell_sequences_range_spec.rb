# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::AlterCellSequencesRange, feature_category: :database do
  describe '#execute' do
    let(:connection) { ApplicationRecord.connection }
    let(:sequence_names) { nil }
    let(:alter_cell_sequences_range) { described_class.new(*params, sequence_names: sequence_names, logger: logger) }
    let(:params) { [minval, maxval, connection] }
    let(:minval) { 100_000 }
    let(:maxval) { 200_000 }
    let(:default_min) { 1 }
    let(:default_max) { (2**63) - 1 }
    let(:logger) { instance_double(Gitlab::AppLogger, info: nil) }

    subject(:execute) { alter_cell_sequences_range.execute }

    shared_examples 'sequences alteration fails' do
      it 'raises an exception' do
        expect { execute }.to raise_error(described_class::MISSING_LIMIT_MSG)
      end
    end

    context 'without minval and maxval' do
      let(:minval) { nil }
      let(:maxval) { nil }

      it_behaves_like 'sequences alteration fails'
    end

    context 'without `maxval` value' do
      let(:maxval) { nil }

      it_behaves_like 'sequences alteration fails'
    end

    context 'without `minval` value' do
      let(:minval) { nil }

      it_behaves_like 'sequences alteration fails'
    end

    shared_examples 'sequence with proper range' do
      it 'ensures the col sequence has the given limits' do
        sequence = connection.execute("SELECT * FROM pg_sequences WHERE sequencename = '#{sequence_name}'").first
        seq_min, seq_max = sequence.values_at('min_value', 'max_value')

        expect([seq_min, seq_max]).to eq([minval, maxval])
      end
    end

    context 'with both minval and maxval' do
      context 'without sequence_names' do
        before do
          execute
        end

        it 'updates given limits for all existing sequences' do
          incorrect_min = Gitlab::Database::PostgresSequence.where.not(seq_min: minval)
          expect(incorrect_min).to be_empty

          incorrect_max = Gitlab::Database::PostgresSequence.where.not(seq_max: maxval)
          expect(incorrect_max).to be_empty

          expect(logger).to have_received(:info)
                              .with("Altering sequences with minval: #{minval}, maxval: #{maxval}")
                              .exactly(:once)
        end

        context 'for newly created sequences' do
          let(:test_table_name) { '_test_sequences_range' }

          before do
            connection.execute <<~SQL
              CREATE TABLE #{test_table_name} (
                id BIGSERIAL PRIMARY KEY,
                int_id SERIAL
              )
            SQL
          end

          after do
            connection.execute("DROP TABLE #{test_table_name}")
          end

          it_behaves_like 'sequence with proper range' do
            let(:sequence_name) { "#{test_table_name}_id_seq" }
          end

          it_behaves_like 'sequence with proper range' do
            let(:sequence_name) { "#{test_table_name}_int_id_seq" }
          end

          context 'with new explicit sequence column added to the existing table' do
            let(:col_name) { 'explicit_id' }
            let(:sequence_name) { "#{test_table_name}_#{col_name}_seq" }

            before do
              connection.execute <<~SQL
                CREATE SEQUENCE #{sequence_name};

                ALTER TABLE #{test_table_name}
                  ADD COLUMN #{col_name} bigint DEFAULT nextval('#{sequence_name}');
              SQL
            end

            it_behaves_like 'sequence with proper range'
          end

          context 'with new implicit sequence column added to the existing table' do
            let(:col_name) { 'implicit_id' }

            before do
              connection.execute <<~SQL
                ALTER TABLE #{test_table_name} ADD COLUMN #{col_name} bigserial;
              SQL
            end

            it_behaves_like 'sequence with proper range' do
              let(:sequence_name) { "#{test_table_name}_#{col_name}_seq" }
            end
          end

          context 'when a sequence is bumped to a higher range via increase_sequences_range' do
            let(:bumped_table_name) { '_test_bumped_sequences_range' }
            let(:bumped_sequence_name) { "#{bumped_table_name}_id_seq" }
            let(:higher_minval) { 300_000 }
            let(:higher_maxval) { 400_000 }

            before do
              # The event trigger is already installed with minval/maxval (100k/200k) from the
              # parent before block's execute call.
              # Create a table whose sequence will be set to 100k/200k by the trigger.
              connection.execute <<~SQL
                CREATE TABLE #{bumped_table_name} (
                  id BIGSERIAL PRIMARY KEY
                );
              SQL

              # Advance the sequence near the end of its range to simulate saturation.
              connection.execute("SELECT setval('#{bumped_sequence_name}', #{maxval - 100})")
            end

            after do
              connection.execute("DROP TABLE #{bumped_table_name}")
            end

            it 'sets the new higher range and the trigger does not revert it' do
              # Simulate what increase_sequences_range does: call execute with a higher range
              # and specific sequence_names. This ALTER SEQUENCE will fire the event trigger
              # which still has the old 100k/200k values baked in.
              bump_logger = instance_double(Gitlab::AppLogger, info: nil)
              described_class.new(
                higher_minval, higher_maxval, connection,
                sequence_names: bumped_sequence_name, logger: bump_logger
              ).execute

              sequence = connection.execute(
                "SELECT * FROM pg_sequences WHERE sequencename = '#{bumped_sequence_name}'"
              ).first

              seq_min, seq_max, seq_start = sequence.values_at('min_value', 'max_value', 'start_value')

              # The sequence should have the new higher range, NOT be reverted to 100k/200k
              expect([seq_min, seq_max, seq_start]).to eq([higher_minval, higher_maxval, higher_minval])
            end

            it 'preserves the bumped range when subsequent DDL fires the trigger' do
              # First bump the sequence
              bump_logger = instance_double(Gitlab::AppLogger, info: nil)
              described_class.new(
                higher_minval, higher_maxval, connection,
                sequence_names: bumped_sequence_name, logger: bump_logger
              ).execute

              # Now create another table, which fires the event trigger again with old 100k/200k
              connection.execute <<~SQL
                CREATE TABLE _test_trigger_fire (id BIGSERIAL PRIMARY KEY)
              SQL

              # The bumped sequence should still retain its higher range
              sequence = connection.execute(
                "SELECT * FROM pg_sequences WHERE sequencename = '#{bumped_sequence_name}'"
              ).first

              seq_min, seq_max = sequence.values_at('min_value', 'max_value')

              expect([seq_min, seq_max]).to eq([higher_minval, higher_maxval])
            ensure
              connection.execute("DROP TABLE IF EXISTS _test_trigger_fire")
            end
          end
        end
      end

      context 'with sequence_names' do
        let(:test_table_name) { '_test_sequences_range_bump' }
        let(:saturating_column_1) { 'saturating_column_1' }
        let(:saturating_column_2) { 'saturating_column_2' }
        let(:saturating_sequence_1) { 'saturating_id_1' }
        let(:saturating_sequence_2) { 'saturating_id_2' }
        let(:sequence_names) { [saturating_sequence_1, saturating_sequence_2] }

        before do
          connection.execute <<~SQL
            CREATE SEQUENCE #{saturating_sequence_1};
            CREATE SEQUENCE #{saturating_sequence_2};

            CREATE TABLE #{test_table_name} (
              #{saturating_column_1} bigint DEFAULT nextval('#{saturating_sequence_1}'),
              #{saturating_column_2} bigint DEFAULT nextval('#{saturating_sequence_2}')
            );
          SQL
        end

        after do
          connection.execute("DROP TABLE #{test_table_name}")
        end

        context 'when minval is greater than last_value (new cell case)' do
          before do
            execute
          end

          it 'restarts the sequence and sets boundaries' do
            sequence = connection.execute(
              "SELECT * FROM pg_sequences WHERE sequencename = '#{saturating_sequence_1}'"
            ).first

            seq_min, seq_max, seq_start = sequence.values_at('min_value', 'max_value', 'start_value')

            expect([seq_min, seq_max, seq_start]).to eq([minval, maxval, minval])
          end

          it_behaves_like 'sequence with proper range' do
            let(:sequence_name) { saturating_sequence_1 }
          end

          it_behaves_like 'sequence with proper range' do
            let(:sequence_name) { saturating_sequence_2 }
          end
        end

        context 'when minval is less than or equal to last_value (legacy cell case)' do
          let(:sequence_name) { saturating_sequence_1 }
          let(:sequence_names) { [sequence_name] }

          before do
            # Set the sequence to have a START value >= minval first, then advance past minval
            connection.execute("ALTER SEQUENCE #{sequence_name} START #{minval}")
            connection.execute("SELECT setval('#{sequence_name}', #{minval + 10})")
            execute
          end

          it 'sets only boundaries without restarting the sequence' do
            sequence = connection.execute(
              "SELECT * FROM pg_sequences WHERE sequencename = '#{sequence_name}'"
            ).first

            seq_min, seq_max = sequence.values_at('min_value', 'max_value')

            expect([seq_min, seq_max]).to eq([minval, maxval])
          end

          it 'logs that RESTART is being skipped' do
            expect(logger).to have_received(:info)
              .with(/Sequence #{sequence_name} already >= minval, skipping RESTART/)
          end
        end

        context 'when sequence already has correct boundaries (no changes needed)' do
          let(:sequence_name) { saturating_sequence_1 }
          let(:sequence_names) { [sequence_name] }

          before do
            # Set the sequence to have correct boundaries already
            connection.execute("ALTER SEQUENCE #{sequence_name} START #{minval}")
            connection.execute("SELECT setval('#{sequence_name}', #{minval + 10})")
            connection.execute("ALTER SEQUENCE #{sequence_name} MINVALUE #{minval} MAXVALUE #{maxval}")
            execute
          end

          it 'skips altering the sequence' do
            sequence = connection.execute(
              "SELECT * FROM pg_sequences WHERE sequencename = '#{sequence_name}'"
            ).first

            seq_min, seq_max = sequence.values_at('min_value', 'max_value')

            expect([seq_min, seq_max]).to eq([minval, maxval])
          end

          it 'does not log RESTART skip message for sequences with correct boundaries' do
            expect(logger).not_to have_received(:info)
              .with(/Sequence #{sequence_name} already >= minval, skipping RESTART/)
          end
        end
      end
    end
  end
end
