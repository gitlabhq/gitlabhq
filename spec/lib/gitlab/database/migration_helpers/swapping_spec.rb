# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::MigrationHelpers::Swapping, feature_category: :database do
  let(:connection) { ApplicationRecord.connection }
  let(:migration_context) do
    ActiveRecord::Migration
      .new
      .extend(described_class)
      .extend(Gitlab::Database::MigrationHelpers)
  end

  let(:service_instance) { instance_double('Gitlab::Database::Migrations::SwapColumns', execute: nil) }

  describe '#swap_columns' do
    let(:table) { :ci_pipeline_variables }
    let(:column1) { :pipeline_id }
    let(:column2) { :pipeline_id_convert_to_bigint }

    it 'calls service' do
      expect(::Gitlab::Database::Migrations::SwapColumns).to receive(:new).with(
        migration_context: migration_context,
        table: table,
        column1: column1,
        column2: column2
      ).and_return(service_instance)

      migration_context.swap_columns(table, column1, column2)
    end
  end

  describe '#swap_columns_default' do
    let(:table) { :_test_table }
    let(:column1) { :pipeline_id }
    let(:column2) { :pipeline_id_convert_to_bigint }

    it 'calls service' do
      expect(::Gitlab::Database::Migrations::SwapColumnsDefault).to receive(:new).with(
        migration_context: migration_context,
        table: table,
        column1: column1,
        column2: column2
      ).and_return(service_instance)

      migration_context.swap_columns_default(table, column1, column2)
    end
  end

  describe '#swap_foreign_keys' do
    let(:table) { :_test_swap_foreign_keys }
    let(:referenced_table) { "#{table}_referenced" }
    let(:foreign_key1) { :fkey_on_integer_column }
    let(:foreign_key2) { :fkey_on_bigint_column }

    before do
      connection.execute(<<~SQL)
        CREATE TABLE #{table} (
          integer_column integer NOT NULL,
          bigint_column bigint DEFAULT 0 NOT NULL
        );
        CREATE TABLE #{referenced_table} (
          id bigint NOT NULL
        );

        ALTER TABLE ONLY #{referenced_table}
          ADD CONSTRAINT pk PRIMARY KEY (id);

        ALTER TABLE ONLY #{table}
          ADD CONSTRAINT #{foreign_key1}
          FOREIGN KEY (integer_column) REFERENCES #{referenced_table}(id) ON DELETE SET NULL;

        ALTER TABLE ONLY #{table}
          ADD CONSTRAINT #{foreign_key2}
          FOREIGN KEY (bigint_column) REFERENCES #{referenced_table}(id) ON DELETE SET NULL;
      SQL
    end

    shared_examples_for 'swapping foreign keys correctly' do
      specify do
        expect { migration_context.swap_foreign_keys(table, foreign_key1, foreign_key2) }
          .to change {
            find_foreign_key_by(foreign_key1).options[:column]
          }.from('integer_column').to('bigint_column')
          .and change {
            find_foreign_key_by(foreign_key2).options[:column]
          }.from('bigint_column').to('integer_column')
      end
    end

    it_behaves_like 'swapping foreign keys correctly'

    context 'when foreign key names are 63 bytes' do
      let(:foreign_key1) { :f1_012345678901234567890123456789012345678901234567890123456789 }
      let(:foreign_key2) { :f2_012345678901234567890123456789012345678901234567890123456789 }

      it_behaves_like 'swapping foreign keys correctly'
    end

    private

    def find_foreign_key_by(name)
      connection.foreign_keys(table).find { |k| k.options[:name].to_s == name.to_s }
    end
  end

  describe '#swap_indexes' do
    let(:table) { :_test_swap_indexes }
    let(:schema) { nil }
    let(:schema_table) { [schema, table].compact.join('.') }
    let(:index1) { :index_on_integer }
    let(:index2) { :index_on_bigint }

    before do
      connection.execute(<<~SQL)
        CREATE TABLE #{schema_table} (
          integer_column integer NOT NULL,
          bigint_column bigint DEFAULT 0 NOT NULL
        );

        CREATE INDEX #{index1} ON #{schema_table} USING btree (integer_column);

        CREATE INDEX #{index2} ON #{schema_table} USING btree (bigint_column);
      SQL
    end

    shared_examples_for 'swapping indexes correctly' do
      specify do
        expect { migration_context.swap_indexes(table, index1, index2, schema: schema) }
          .to change { find_index_by(index1).columns }.from(['integer_column']).to(['bigint_column'])
          .and change { find_index_by(index2).columns }.from(['bigint_column']).to(['integer_column'])
      end
    end

    it_behaves_like 'swapping indexes correctly'

    context 'when index names are 63 bytes' do
      let(:index1) { :i1_012345678901234567890123456789012345678901234567890123456789 }
      let(:index2) { :i2_012345678901234567890123456789012345678901234567890123456789 }

      it_behaves_like 'swapping indexes correctly'
    end

    context 'for schema' do
      let(:schema) { :gitlab_partitions_dynamic }

      it_behaves_like 'swapping indexes correctly'
    end

    private

    def find_index_by(name)
      connection.indexes(schema_table).find { |c| c.name == name.to_s }
    end
  end
end
