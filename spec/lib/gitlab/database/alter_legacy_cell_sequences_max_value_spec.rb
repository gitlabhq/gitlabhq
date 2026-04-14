# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::AlterLegacyCellSequencesMaxValue, feature_category: :database do
  let(:connection) { ApplicationRecord.connection }
  let(:sequence_names) { nil }
  let(:maxval) { 999_999_999_999 }
  let(:default_max) { (2**63) - 1 }
  let(:logger) { instance_double(Gitlab::AppLogger, info: nil) }
  let(:alter_legacy_cell_sequences_max_value) do
    described_class.new(maxval, connection, sequence_names: sequence_names, logger: logger)
  end

  describe '#execute' do
    subject(:execute) { alter_legacy_cell_sequences_max_value.execute }

    context 'without maxval' do
      let(:maxval) { nil }

      it 'raises an exception' do
        expect { execute }.to raise_error(described_class::MISSING_MAXVAL_MSG)
      end
    end

    shared_examples 'sequence with proper max value' do
      it 'ensures the sequence has the given max value' do
        sequence = connection.execute("SELECT * FROM pg_sequences WHERE sequencename = '#{sequence_name}'").first
        seq_max = sequence['max_value']

        expect(seq_max).to eq(maxval)
      end
    end

    context 'without sequence_names' do
      before do
        execute
      end

      it 'updates max value for all sequences' do
        incorrect_max = Gitlab::Database::PostgresSequence.where.not(seq_max: maxval)
        expect(incorrect_max).to be_empty

        expect(logger).to have_received(:info)
                            .with("Altering sequences max value to: #{maxval}")
                            .exactly(:once)
      end

      context 'for newly created sequences' do
        let(:test_table_name) { '_test_legacy_max_value_range' }

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

        it_behaves_like 'sequence with proper max value' do
          let(:sequence_name) { "#{test_table_name}_id_seq" }
        end

        it 'does not alter the integer SERIAL sequence' do
          sequence = connection.execute(
            "SELECT * FROM pg_sequences WHERE sequencename = '#{test_table_name}_int_id_seq'"
          ).first

          expect(sequence['max_value']).not_to eq(maxval)
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

          it_behaves_like 'sequence with proper max value'
        end

        context 'with new implicit sequence column added to the existing table' do
          let(:col_name) { 'implicit_id' }

          before do
            connection.execute <<~SQL
              ALTER TABLE #{test_table_name} ADD COLUMN #{col_name} bigserial;
            SQL
          end

          it_behaves_like 'sequence with proper max value' do
            let(:sequence_name) { "#{test_table_name}_#{col_name}_seq" }
          end
        end

        context 'when a sequence is bumped to a higher range via increase_sequences_range' do
          let(:bumped_table_name) { '_test_bumped_legacy_max_value' }
          let(:bumped_sequence_name) { "#{bumped_table_name}_id_seq" }
          let(:higher_minval) { 1_000_000_000_000 }
          let(:higher_maxval) { 1_999_999_999_999 }

          before do
            connection.execute <<~SQL
              CREATE TABLE #{bumped_table_name} (
                id BIGSERIAL PRIMARY KEY
              );
            SQL
          end

          after do
            connection.execute("DROP TABLE #{bumped_table_name}")
          end

          it 'preserves the bumped range when subsequent DDL fires the trigger' do
            bump_logger = instance_double(Gitlab::AppLogger, info: nil)
            Gitlab::Database::AlterCellSequencesRange.new(
              higher_minval, higher_maxval, connection,
              sequence_names: bumped_sequence_name, logger: bump_logger
            ).execute

            connection.execute <<~SQL
              CREATE TABLE _test_trigger_fire_legacy (id BIGSERIAL PRIMARY KEY)
            SQL

            sequence = connection.execute(
              "SELECT * FROM pg_sequences WHERE sequencename = '#{bumped_sequence_name}'"
            ).first

            seq_min, seq_max = sequence.values_at('min_value', 'max_value')

            expect([seq_min, seq_max]).to eq([higher_minval, higher_maxval])
          ensure
            connection.execute("DROP TABLE IF EXISTS _test_trigger_fire_legacy")
          end
        end
      end
    end

    context 'with skip_trigger_install' do
      let(:alter_legacy_cell_sequences_max_value) do
        described_class.new(maxval, connection, skip_trigger_install: true, logger: logger)
      end

      before do
        execute
      end

      it 'updates max value for all sequences' do
        incorrect_max = Gitlab::Database::PostgresSequence.where.not(seq_max: maxval)
        expect(incorrect_max).to be_empty
      end

      it 'installs the function' do
        function = connection.execute(
          "SELECT proname FROM pg_proc WHERE proname = '#{described_class::FUNCTION_NAME}'"
        ).first

        expect(function).to be_present
      end

      it 'does not install the event trigger' do
        trigger = connection.execute(
          "SELECT * FROM pg_event_trigger WHERE evtname = '#{described_class::TRIGGER_NAME}'"
        ).first

        expect(trigger).to be_nil
      end

      it 'logs that event trigger installation was skipped' do
        expect(logger).to have_received(:info)
          .with("Skipping event trigger installation as SKIP_SEQUENCE_TRIGGER_INSTALL is set")
      end
    end

    context 'with sequence_names' do
      let(:test_table_name) { '_test_legacy_max_value_specific' }
      let(:target_sequence_1) { 'legacy_max_val_seq_1' }
      let(:target_sequence_2) { 'legacy_max_val_seq_2' }
      let(:sequence_names) { [target_sequence_1, target_sequence_2] }

      before do
        connection.execute <<~SQL
          CREATE SEQUENCE #{target_sequence_1};
          CREATE SEQUENCE #{target_sequence_2};

          CREATE TABLE #{test_table_name} (
            col_1 bigint DEFAULT nextval('#{target_sequence_1}'),
            col_2 bigint DEFAULT nextval('#{target_sequence_2}')
          );
        SQL
      end

      after do
        connection.execute("DROP TABLE #{test_table_name}")
      end

      it 'alters only the specified sequences' do
        execute

        [target_sequence_1, target_sequence_2].each do |seq_name|
          sequence = connection.execute(
            "SELECT * FROM pg_sequences WHERE sequencename = '#{seq_name}'"
          ).first

          expect(sequence['max_value']).to eq(maxval)
        end
      end

      it 'does not install the event trigger when sequence_names are provided' do
        execute

        trigger = connection.execute(
          "SELECT * FROM pg_event_trigger WHERE evtname = '#{described_class::TRIGGER_NAME}'"
        ).first

        expect(trigger).to be_nil
      end

      context 'when sequence already has the correct max value' do
        let(:sequence_names) { [target_sequence_1] }

        before do
          connection.execute("ALTER SEQUENCE #{target_sequence_1} MAXVALUE #{maxval}")
          execute
        end

        it 'skips altering the sequence' do
          sequence = connection.execute(
            "SELECT * FROM pg_sequences WHERE sequencename = '#{target_sequence_1}'"
          ).first

          expect(sequence['max_value']).to eq(maxval)
        end
      end

      context 'when verifying only max_value is changed' do
        let(:unchanged_seq) { '_test_legacy_unchanged_attrs_seq' }
        let(:sequence_names) { [unchanged_seq] }

        before do
          connection.execute("CREATE SEQUENCE #{unchanged_seq} MINVALUE 100 START 100")
          connection.execute("SELECT setval('#{unchanged_seq}', 500)")
          execute
        end

        after do
          connection.execute("DROP SEQUENCE IF EXISTS #{unchanged_seq}")
        end

        it 'does not change min_value' do
          sequence = connection.execute(
            "SELECT * FROM pg_sequences WHERE sequencename = '#{unchanged_seq}'"
          ).first

          expect(sequence['min_value']).to eq(100)
        end

        it 'does not change start_value' do
          sequence = connection.execute(
            "SELECT * FROM pg_sequences WHERE sequencename = '#{unchanged_seq}'"
          ).first

          expect(sequence['start_value']).to eq(100)
        end

        it 'preserves last_value when it is below the new max value' do
          sequence = connection.execute(
            "SELECT * FROM pg_sequences WHERE sequencename = '#{unchanged_seq}'"
          ).first

          expect(sequence['last_value']).to eq(500)
        end
      end

      context 'when last_value exceeds the new max value' do
        let(:sequence_names) { [target_sequence_1] }

        it 'raises a database error' do
          connection.execute("SELECT setval('#{target_sequence_1}', #{maxval + 1})")

          expect { execute }
            .to raise_error(ActiveRecord::StatementInvalid, /cannot be greater than MAXVALUE/)
        end
      end
    end
  end

  describe '#rollback' do
    subject(:rollback) { alter_legacy_cell_sequences_max_value.rollback }

    context 'without sequence_names' do
      before do
        alter_legacy_cell_sequences_max_value.execute
      end

      it 'resets max value to default for all sequences' do
        rollback

        incorrect_max = Gitlab::Database::PostgresSequence.where.not(seq_max: default_max)
        expect(incorrect_max).to be_empty
      end

      it 'drops the event trigger and function' do
        rollback

        trigger = connection.execute(
          "SELECT * FROM pg_event_trigger WHERE evtname = '#{described_class::TRIGGER_NAME}'"
        ).first

        expect(trigger).to be_nil
      end

      it 'logs the rollback' do
        rollback

        expect(logger).to have_received(:info)
                            .with("Rolling back sequences max value to default: #{default_max}")
      end
    end

    context 'with sequence_names' do
      let(:test_table_name) { '_test_legacy_rollback_specific' }
      let(:target_sequence) { 'legacy_rollback_seq_1' }
      let(:sequence_names) { [target_sequence] }

      before do
        connection.execute <<~SQL
          CREATE SEQUENCE #{target_sequence};

          CREATE TABLE #{test_table_name} (
            col_1 bigint DEFAULT nextval('#{target_sequence}')
          );
        SQL

        described_class.new(maxval, connection, sequence_names: sequence_names, logger: logger).execute
      end

      after do
        connection.execute("DROP TABLE #{test_table_name}")
      end

      it 'resets max value to default for specified sequences' do
        rollback

        sequence = connection.execute(
          "SELECT * FROM pg_sequences WHERE sequencename = '#{target_sequence}'"
        ).first

        expect(sequence['max_value']).to eq(default_max)
      end

      context 'when sequence already has the default max value' do
        before do
          connection.execute("ALTER SEQUENCE #{target_sequence} MAXVALUE #{default_max}")
        end

        it 'skips altering the sequence' do
          rollback

          sequence = connection.execute(
            "SELECT * FROM pg_sequences WHERE sequencename = '#{target_sequence}'"
          ).first

          expect(sequence['max_value']).to eq(default_max)
        end
      end

      it 'does not drop the event trigger when sequence_names are provided' do
        described_class.new(maxval, connection, logger: logger).execute

        rollback

        trigger = connection.execute(
          "SELECT * FROM pg_event_trigger WHERE evtname = '#{described_class::TRIGGER_NAME}'"
        ).first

        expect(trigger).to be_present
      ensure
        described_class.new(maxval, connection, logger: logger).drop_event_trigger
      end
    end
  end

  describe '#drop_event_trigger' do
    before do
      alter_legacy_cell_sequences_max_value.execute
    end

    it 'drops the event trigger and function' do
      alter_legacy_cell_sequences_max_value.drop_event_trigger

      trigger = connection.execute(
        "SELECT * FROM pg_event_trigger WHERE evtname = '#{described_class::TRIGGER_NAME}'"
      ).first

      expect(trigger).to be_nil
    end
  end
end
