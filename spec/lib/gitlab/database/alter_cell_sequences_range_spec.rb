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

        context 'with minval less than last value of the sequence' do
          before do
            connection.execute <<~SQL
              ALTER TABLE #{test_table_name} ADD COLUMN test_invalid_sequence_id BIGSERIAL;
              SELECT nextval('#{sequence_name}');
            SQL
          end

          let(:sequence_name) { "#{test_table_name}_test_invalid_sequence_id_seq" }
          let(:sequence_names) { [sequence_name] }
          let(:minval) { 1 }

          it 'throws an error' do
            expect { execute }
              .to raise_error("`minval` should be greater than the `last_value` of the sequence #{sequence_name}")
          end
        end

        context 'with correct minval' do
          before do
            execute
          end

          it_behaves_like 'sequence with proper range' do
            let(:sequence_name) { saturating_sequence_1 }
          end

          it_behaves_like 'sequence with proper range' do
            let(:sequence_name) { saturating_sequence_2 }
          end
        end
      end
    end
  end
end
