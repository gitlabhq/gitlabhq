# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::CopyColumnUsingBackgroundMigrationJob, feature_category: :database do
  it { expect(described_class).to be < Gitlab::BackgroundMigration::BatchedMigrationJob }

  describe '#perform' do
    let(:table_name) { :_test_copy_primary_key_test }
    let(:test_table) { table(table_name) }
    let(:sub_batch_size) { 1000 }
    let(:pause_ms) { 0 }
    let(:connection) { ApplicationRecord.connection }

    let(:helpers) do
      ActiveRecord::Migration.new.extend(Gitlab::Database::MigrationHelpers)
    end

    let(:job_arguments) { %w[name name_convert_to_text] }
    let(:copy_job) do
      described_class.new(
        start_id: 12,
        end_id: 20,
        batch_table: table_name,
        batch_column: 'id',
        sub_batch_size: sub_batch_size,
        pause_ms: pause_ms,
        job_arguments: job_arguments,
        connection: connection
      )
    end

    let(:create_table) do
      connection.execute(<<~SQL)
        CREATE TABLE #{table_name}
        (
         id integer NOT NULL,
         name character varying,
         fk integer NOT NULL,
         #{helpers.convert_to_bigint_column(:id)} bigint DEFAULT 0 NOT NULL,
         #{helpers.convert_to_bigint_column(:fk)} bigint DEFAULT 0 NOT NULL,
         name_convert_to_text text DEFAULT 'no name'
        );
      SQL
    end

    before do
      create_table

      # Insert some data, it doesn't make a difference
      test_table.create!(id: 11, name: 'test1', fk: 1)
      test_table.create!(id: 12, name: 'test2', fk: 2)
      test_table.create!(id: 15, name: nil, fk: 3)
      test_table.create!(id: 19, name: 'test4', fk: 4)
    end

    after do
      # Make sure that the temp table we created is dropped (it is not removed by the database_cleaner)
      connection.execute(<<~SQL)
        DROP TABLE IF EXISTS #{table_name};
      SQL
    end

    context 'primary keys' do
      let(:temporary_column) { helpers.convert_to_bigint_column(:id) }
      let(:job_arguments) { ['id', temporary_column] }

      it 'copies all in range' do
        copy_job.perform

        expect(test_table.count).to eq(4)
        expect(test_table.where("id = #{temporary_column}").pluck(:id)).to contain_exactly(12, 15, 19)
        expect(test_table.where(temporary_column => 0).pluck(:id)).to contain_exactly(11)
      end
    end

    context 'foreign keys' do
      let(:temporary_column) { helpers.convert_to_bigint_column(:fk) }
      let(:job_arguments) { ['fk', temporary_column] }

      it 'copies all in range' do
        copy_job.perform

        expect(test_table.count).to eq(4)
        expect(test_table.where("fk = #{temporary_column}").pluck(:id)).to contain_exactly(12, 15, 19)
        expect(test_table.where(temporary_column => 0).pluck(:id)).to contain_exactly(11)
      end
    end

    context 'columns with NULLs' do
      let(:job_arguments) { %w[name name_convert_to_text] }

      it 'copies all in range' do
        expect { copy_job.perform }
          .to change { test_table.where("name_convert_to_text = 'no name'").count }.from(4).to(1)

        expect(test_table.where('name = name_convert_to_text').pluck(:id)).to contain_exactly(12, 19)
        expect(test_table.where('name is NULL and name_convert_to_text is NULL').pluck(:id)).to contain_exactly(15)
      end
    end

    context 'when multiple columns are given' do
      let(:id_tmp_column) { helpers.convert_to_bigint_column('id') }
      let(:fk_tmp_column) { helpers.convert_to_bigint_column('fk') }
      let(:columns_to_copy_from) { %w[id fk] }
      let(:columns_to_copy_to) { [id_tmp_column, fk_tmp_column] }

      let(:job_arguments) { [columns_to_copy_from, columns_to_copy_to] }

      it 'copies all values in the range' do
        copy_job.perform

        expect(test_table.count).to eq(4)
        expect(test_table.where("id = #{id_tmp_column} AND fk = #{fk_tmp_column}").pluck(:id)).to contain_exactly(12, 15, 19)
        expect(test_table.where(id_tmp_column => 0).where(fk_tmp_column => 0).pluck(:id)).to contain_exactly(11)
      end

      context 'when the number of source and target columns does not match' do
        let(:columns_to_copy_to) { [id_tmp_column] }

        it 'raises an error' do
          expect do
            copy_job.perform
          end.to raise_error(ArgumentError, 'number of source and destination columns must match')
        end
      end
    end

    it 'tracks timings of queries' do
      expect(copy_job.batch_metrics.timings).to be_empty

      copy_job.perform

      expect(copy_job.batch_metrics.timings[:update_all]).not_to be_empty
    end

    context 'pause interval between sub-batches' do
      let(:pause_ms) { 5 }

      it 'sleeps for the specified time between sub-batches' do
        expect(copy_job).to receive(:sleep).with(0.005)

        copy_job.perform
      end

      context 'when pause_ms value is negative' do
        let(:pause_ms) { -5 }

        it 'treats it as a 0' do
          expect(copy_job).to receive(:sleep).with(0)

          copy_job.perform
        end
      end
    end

    context 'when given column does not exist' do
      let(:create_table) do
        connection.execute(<<~SQL)
          CREATE TABLE #{table_name}
          (
          id integer NOT NULL,
          name character varying,
          fk integer NOT NULL,
          #{helpers.convert_to_bigint_column(:id)} bigint DEFAULT 0 NOT NULL,
          #{helpers.convert_to_bigint_column(:fk)} bigint DEFAULT 0 NOT NULL
          );
        SQL
      end

      context 'when all given columns not exist' do
        it 'does nothing' do
          expect(copy_job.batch_metrics.timings).to be_empty

          expect { copy_job.perform }.not_to raise_error

          expect(copy_job.batch_metrics.timings).to be_empty
        end
      end

      context 'when some of given columns not exist' do
        let(:job_arguments) { [%w[id fk name], %w[id_convert_to_bigint fk_convert_to_bigint name_convert_to_text]] }

        it 'copies the values for the columns exist' do
          expect { copy_job.perform }.not_to raise_error

          expect(test_table.where("id = id_convert_to_bigint AND fk = fk_convert_to_bigint").pluck(:id)).to contain_exactly(12, 15, 19)
          expect(test_table.where(id_convert_to_bigint: 0).where(fk_convert_to_bigint: 0).pluck(:id)).to contain_exactly(11)
        end
      end
    end
  end
end
