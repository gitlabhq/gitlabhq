# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PostgresConstraint, type: :model do
  # PostgresConstraint does not `behaves_like 'a postgres model'` because it does not correspond 1-1 with a single entry
  # in pg_class
  let(:schema) { ActiveRecord::Base.connection.current_schema }
  let(:table_name) { '_test_table' }
  let(:table_identifier) { "#{schema}.#{table_name}" }
  let(:referenced_name) { '_test_referenced' }
  let(:check_constraint_a_positive) { 'check_constraint_a_positive' }
  let(:check_constraint_a_gt_b) { 'check_constraint_a_gt_b' }
  let(:invalid_constraint_a) { 'check_constraint_b_positive_invalid' }
  let(:unique_constraint_a) { "#{table_name}_a_key" }

  before do
    ActiveRecord::Base.connection.execute(<<~SQL)
    create table #{referenced_name} (
      id bigserial primary key not null
    );

    create table #{table_name} (
      id bigserial not null,
      referenced_id bigint not null references #{referenced_name}(id),
      a integer unique,
      b integer,
      primary key (id, referenced_id),
      constraint #{check_constraint_a_positive} check (a > 0),
      constraint #{check_constraint_a_gt_b} check (a > b)
    );

    alter table #{table_name} add constraint #{invalid_constraint_a} CHECK (a > 1) NOT VALID;
    SQL
  end

  describe '#by_table_identifier' do
    subject(:constraints_for_table) { described_class.by_table_identifier(table_identifier) }

    it 'includes all constraints on the table' do
      all_constraints_for_table = described_class.all.to_a.select { |c| c.table_identifier == table_identifier }
      expect(all_constraints_for_table.map(&:oid)).to match_array(constraints_for_table.pluck(:oid))
    end

    it 'throws an error if the format is incorrect' do
      expect { described_class.by_table_identifier('not-an-identifier') }.to raise_error(ArgumentError)
    end
  end

  describe '#check_constraints' do
    subject(:check_constraints) { described_class.check_constraints.by_table_identifier(table_identifier) }

    it 'finds check constraints for the table' do
      expect(check_constraints.map(&:name)).to contain_exactly(
        check_constraint_a_positive,
        check_constraint_a_gt_b,
        invalid_constraint_a
      )
    end

    it 'includes columns for the check constraints', :aggregate_failures do
      expect(check_constraints.find_by(name: check_constraint_a_positive).column_names).to contain_exactly('a')
      expect(check_constraints.find_by(name: check_constraint_a_gt_b).column_names).to contain_exactly('a', 'b')
    end
  end

  describe "#valid" do
    subject(:valid_constraint_names) { described_class.valid.by_table_identifier(table_identifier).pluck(:name) }

    let(:all_constraint_names) { described_class.by_table_identifier(table_identifier).pluck(:name) }

    it 'excludes invalid constraints' do
      expect(valid_constraint_names).not_to include(invalid_constraint_a)
      expect(valid_constraint_names).to match_array(all_constraint_names - [invalid_constraint_a])
    end
  end

  describe '#primary_key_constraints' do
    subject(:pk_constraints) { described_class.primary_key_constraints.by_table_identifier(table_identifier) }

    it 'finds the primary key constraint for the table' do
      expect(pk_constraints.count).to eq(1)
      expect(pk_constraints.first.constraint_type).to eq('p')
    end

    it 'finds the columns in the primary key constraint' do
      constraint = pk_constraints.first
      expect(constraint.column_names).to contain_exactly('id', 'referenced_id')
    end
  end

  describe '#unique_constraints' do
    subject(:unique_constraints) { described_class.unique_constraints.by_table_identifier(table_identifier) }

    it 'finds the unique constraints for the table' do
      expect(unique_constraints.pluck(:name)).to contain_exactly(unique_constraint_a)
    end
  end

  describe '#primary_or_unique_constraints' do
    subject(:pk_or_unique_constraints) do
      described_class.primary_or_unique_constraints.by_table_identifier(table_identifier)
    end

    it 'finds primary and unique constraints' do
      expect(pk_or_unique_constraints.pluck(:name)).to contain_exactly("#{table_name}_pkey", unique_constraint_a)
    end
  end

  describe '#including_column' do
    it 'only matches constraints on the given column' do
      constraints_on_a = described_class.by_table_identifier(table_identifier).including_column('a').map(&:name)
      expect(constraints_on_a).to contain_exactly(
        check_constraint_a_positive,
        check_constraint_a_gt_b,
        unique_constraint_a,
        invalid_constraint_a
      )
    end
  end

  describe '#not_including_column' do
    it 'only matches constraints not including the given column' do
      constraints_not_on_a = described_class.by_table_identifier(table_identifier).not_including_column('a').map(&:name)

      expect(constraints_not_on_a).to contain_exactly("#{table_name}_pkey", "#{table_name}_referenced_id_fkey")
    end
  end
end
