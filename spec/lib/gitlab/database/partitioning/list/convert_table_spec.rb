# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::List::ConvertTable, feature_category: :database do
  include Gitlab::Database::DynamicModelHelpers
  include Database::TableSchemaHelpers
  include Database::InjectFailureHelpers

  include_context 'with a table structure for converting a table to a list partition'

  let(:converter) do
    described_class.new(
      migration_context: migration_context,
      table_name: table_name,
      partitioning_column: partitioning_column,
      parent_table_name: parent_table_name,
      zero_partition_value: partitioning_default,
      lock_tables: lock_tables
    )
  end

  describe "#prepare_for_partitioning" do
    subject(:prepare) { converter.prepare_for_partitioning(async: async) }

    let(:async) { false }

    it 'adds a check constraint' do
      expect { prepare }.to change {
        Gitlab::Database::PostgresConstraint
          .check_constraints
          .by_table_identifier(table_identifier)
          .count
      }.from(0).to(1)
    end

    context 'when it fails to add constraint' do
      before do
        allow(migration_context).to receive(:add_check_constraint)
      end

      it 'raises UnableToPartition error' do
        expect { prepare }
          .to raise_error(described_class::UnableToPartition)
          .and change {
            Gitlab::Database::PostgresConstraint
              .check_constraints
              .by_table_identifier(table_identifier)
              .count
          }.by(0)
      end
    end

    context 'when async' do
      let(:async) { true }

      it 'adds a NOT VALID check constraint' do
        expect { prepare }.to change {
          Gitlab::Database::PostgresConstraint
            .check_constraints
            .by_table_identifier(table_identifier)
            .count
        }.from(0).to(1)

        constraint =
          Gitlab::Database::PostgresConstraint
            .check_constraints
            .by_table_identifier(table_identifier)
            .last

        expect(constraint.definition).to end_with('NOT VALID')
      end

      it 'adds a PostgresAsyncConstraintValidation record' do
        expect { prepare }.to change {
          Gitlab::Database::AsyncConstraints::PostgresAsyncConstraintValidation.count
        }.from(0).to(1)

        record = Gitlab::Database::AsyncConstraints::PostgresAsyncConstraintValidation.last
        expect(record.name).to eq described_class::PARTITIONING_CONSTRAINT_NAME
        expect(record).to be_check_constraint
      end

      context 'when constraint exists but is not valid' do
        before do
          converter.prepare_for_partitioning(async: true)
        end

        it 'validates the check constraint' do
          expect { prepare }.to change {
            Gitlab::Database::PostgresConstraint
            .check_constraints
            .by_table_identifier(table_identifier).first.constraint_valid?
          }.from(false).to(true)
        end

        context 'when it fails to validate constraint' do
          before do
            allow(migration_context).to receive(:validate_check_constraint)
          end

          it 'raises UnableToPartition error' do
            expect { prepare }
              .to raise_error(described_class::UnableToPartition,
                starting_with('Error validating partitioning constraint'))
              .and change {
                Gitlab::Database::PostgresConstraint
                  .check_constraints
                  .by_table_identifier(table_identifier)
                  .count
              }.by(0)
          end
        end
      end

      context 'when constraint exists and is valid' do
        before do
          converter.prepare_for_partitioning(async: false)
        end

        it 'raises UnableToPartition error' do
          expect(Gitlab::AppLogger).to receive(:info).with(starting_with('Nothing to do'))
          prepare
        end
      end
    end
  end

  describe '#revert_preparation_for_partitioning' do
    before do
      converter.prepare_for_partitioning
    end

    subject(:revert_prepare) { converter.revert_preparation_for_partitioning }

    it 'removes a check constraint' do
      expect { revert_prepare }.to change {
        Gitlab::Database::PostgresConstraint
          .check_constraints
          .by_table_identifier("#{connection.current_schema}.#{table_name}")
          .count
      }.from(1).to(0)
    end
  end

  describe "#partition" do
    subject(:partition) { converter.partition }

    let(:async) { false }

    before do
      converter.prepare_for_partitioning(async: async)
    end

    context 'when the primary key is incorrect' do
      before do
        connection.execute(<<~SQL)
          alter table #{referencing_table_name} drop constraint fk_referencing; -- this depends on the primary key
          alter table #{other_referencing_table_name} drop constraint fk_referencing_other; -- this does too
          alter table #{table_name} drop constraint #{table_name}_pkey;
          alter table #{table_name} add constraint #{table_name}_pkey PRIMARY KEY (id);
        SQL
      end

      it 'throws a reasonable error message' do
        expect { partition }.to raise_error(described_class::UnableToPartition, /#{partitioning_column}/)
      end
    end

    context 'when there is not a supporting check constraint' do
      before do
        connection.execute(<<~SQL)
          alter table #{table_name} drop constraint partitioning_constraint;
        SQL
      end

      it 'throws a reasonable error message' do
        expect { partition }.to raise_error(described_class::UnableToPartition, /is not ready for partitioning./)
      end
    end

    context 'when supporting check constraint is not valid' do
      let(:async) { true }

      it 'throws a reasonable error message' do
        expect { partition }.to raise_error(described_class::UnableToPartition, /is not ready for partitioning./)
      end
    end

    it 'migrates the table to a partitioned table' do
      fks_before = migration_context.foreign_keys(table_name)

      partition

      expect(Gitlab::Database::PostgresPartition.for_parent_table(parent_table_name).count).to eq(1)
      expect(migration_context.foreign_keys(parent_table_name).map(&:options)).to match_array(fks_before.map(&:options))

      connection.execute(<<~SQL)
        insert into #{table_name} (referenced_id, other_referenced_id) select #{referenced_table_name}.id, #{other_referenced_table_name}.id from #{referenced_table_name}, #{other_referenced_table_name};
      SQL

      # Create a second partition
      connection.execute(<<~SQL)
        create table #{table_name}2 partition of #{parent_table_name} FOR VALUES IN (2)
      SQL

      parent_model.create!(partitioning_column => 2, :referenced_id => 1, :other_referenced_id => 1)
      expect(parent_model.pluck(:id)).to match_array([1, 2, 3])

      expect { referencing_model.create!(partitioning_column => 1, :ref_id => 1) }.not_to raise_error
    end

    context 'when the existing table is owned by a different user' do
      before do
        connection.execute(<<~SQL)
          CREATE USER other_user SUPERUSER;
          ALTER TABLE #{table_name} OWNER TO other_user;
        SQL
      end

      let(:current_user) { model.connection.select_value('select current_user') }

      it 'partitions without error' do
        expect { partition }.not_to raise_error
      end
    end

    context 'with locking tables' do
      let(:lock_tables) { [table_name] }

      it 'locks the table' do
        recorder = ActiveRecord::QueryRecorder.new { partition }

        expect(recorder.log).to include(/LOCK "_test_table_to_partition" IN ACCESS EXCLUSIVE MODE/)
      end
    end

    context 'when an error occurs during the conversion' do
      before do
        # Set up the fault that we'd like to inject
        fault.call
      end

      let(:old_fks) do
        Gitlab::Database::PostgresForeignKey.by_referenced_table_identifier(table_identifier).not_inherited
      end

      let(:new_fks) do
        Gitlab::Database::PostgresForeignKey.by_referenced_table_identifier(parent_table_identifier).not_inherited
      end

      context 'when partitioning fails the first time' do
        where(:case_name, :fault) do
          [
            ["creating parent table", lazy { fail_sql_matching(/CREATE/i) }],
            ["adding the first foreign key", lazy { fail_adding_fk(parent_table_name, referenced_table_name) }],
            ["adding the second foreign key", lazy { fail_adding_fk(parent_table_name, other_referenced_table_name) }],
            ["attaching table", lazy { fail_sql_matching(/ATTACH/i) }]
          ]
        end

        with_them do
          it 'recovers from a fault', :aggregate_failures do
            expect { converter.partition }.to raise_error(/fault/)
            expect(Gitlab::Database::PostgresPartition.for_parent_table(parent_table_name).count).to eq(0)

            expect { converter.partition }.not_to raise_error
            expect(Gitlab::Database::PostgresPartition.for_parent_table(parent_table_name).count).to eq(1)
          end
        end
      end
    end

    context 'when table has LFK triggers' do
      before do
        migration_context.track_record_deletions(table_name)
      end

      it 'moves the trigger on the parent table', :aggregate_failures do
        expect(migration_context.has_loose_foreign_key?(table_name)).to be_truthy

        expect { partition }.not_to raise_error

        expect(migration_context.has_loose_foreign_key?(table_name)).to be_truthy
        expect(migration_context.has_loose_foreign_key?(parent_table_name)).to be_truthy
      end
    end
  end

  describe '#revert_partitioning' do
    before do
      converter.prepare_for_partitioning
      converter.partition
    end

    subject(:revert_conversion) { converter.revert_partitioning }

    it 'detaches the partition' do
      expect { revert_conversion }.to change {
        Gitlab::Database::PostgresPartition
          .for_parent_table(parent_table_name).count
      }.from(1).to(0)
    end

    it 'does not drop the child partition' do
      expect { revert_conversion }.not_to change { table_oid(table_name) }
    end

    it 'removes the parent table' do
      expect { revert_conversion }.to change { table_oid(parent_table_name).present? }.from(true).to(false)
    end

    it 're-adds the check constraint' do
      expect { revert_conversion }.to change {
        Gitlab::Database::PostgresConstraint
          .check_constraints
          .by_table_identifier(table_identifier)
          .count
      }.by(1)
    end

    it 'moves sequences back to the original table' do
      expect { revert_conversion }.to change { converter.send(:sequences_owned_by, table_name).count }.from(0)
                                 .and change { converter.send(:sequences_owned_by, parent_table_name).count }.to(0)
    end

    context 'when table has LFK triggers' do
      before do
        migration_context.track_record_deletions(parent_table_name)
        migration_context.track_record_deletions(table_name)
      end

      it 'restores the trigger on the partition', :aggregate_failures do
        expect(migration_context.has_loose_foreign_key?(table_name)).to be_truthy
        expect(migration_context.has_loose_foreign_key?(parent_table_name)).to be_truthy

        expect { revert_conversion }.not_to raise_error

        expect(migration_context.has_loose_foreign_key?(table_name)).to be_truthy
      end
    end
  end
end
