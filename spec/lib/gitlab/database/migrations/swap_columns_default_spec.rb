# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::SwapColumnsDefault, feature_category: :database do
  describe '#execute' do
    let(:connection) { ApplicationRecord.connection }
    let(:migration_context) do
      Gitlab::Database::Migration[2.1]
        .new('name', 'version')
        .extend(Gitlab::Database::MigrationHelpers::Swapping)
    end

    let(:table) { :_test_swap_columns_and_defaults }
    let(:column1) { :integer_column }
    let(:column2) { :bigint_column }

    subject(:execute_service) do
      described_class.new(
        migration_context: migration_context,
        table: table,
        column1: column1,
        column2: column2
      ).execute
    end

    before do
      connection.execute(sql)
    end

    context 'when defaults are static values' do
      let(:sql) do
        <<~SQL
          CREATE TABLE #{table} (
            id integer NOT NULL,
            #{column1} integer DEFAULT 8 NOT NULL,
            #{column2} bigint DEFAULT 100 NOT NULL
          );
        SQL
      end

      it 'swaps the default correctly' do
        expect { execute_service }
          .to change { find_column_by(column1).default }.to('100')
          .and change { find_column_by(column2).default }.to('8')
          .and not_change { find_column_by(column1).default_function }.from(nil)
          .and not_change { find_column_by(column2).default_function }.from(nil)
      end
    end

    context 'when default is sequence' do
      let(:sql) do
        <<~SQL
          CREATE TABLE #{table} (
            id integer NOT NULL,
            #{column1} integer NOT NULL,
            #{column2} bigint DEFAULT 100 NOT NULL
          );

          CREATE SEQUENCE #{table}_seq
            START WITH 1
            INCREMENT BY 1
            NO MINVALUE
            NO MAXVALUE
            CACHE 1;

          ALTER SEQUENCE #{table}_seq OWNED BY #{table}.#{column1};
          ALTER TABLE ONLY #{table} ALTER COLUMN #{column1} SET DEFAULT nextval('#{table}_seq'::regclass);
        SQL
      end

      it 'swaps the default correctly' do
        recorder = nil
        expect { recorder = ActiveRecord::QueryRecorder.new { execute_service } }
          .to change { find_column_by(column1).default }.to('100')
          .and change { find_column_by(column1).default_function }.to(nil)
          .and change { find_column_by(column2).default }.to(nil)
          .and change {
            find_column_by(column2).default_function
          }.to("nextval('_test_swap_columns_and_defaults_seq'::regclass)")
        expect(recorder.log).to include(
          /SEQUENCE "_test_swap_columns_and_defaults_seq" OWNED BY "_test_swap_columns_and_defaults"."bigint_column"/
        )
        expect(recorder.log).to include(
          /COLUMN "bigint_column" SET DEFAULT nextval\('_test_swap_columns_and_defaults_seq'::regclass\)/
        )
      end
    end

    context 'when defaults are the same' do
      let(:sql) do
        <<~SQL
          CREATE TABLE #{table} (
            id integer NOT NULL,
            #{column1} integer DEFAULT 100 NOT NULL,
            #{column2} bigint DEFAULT 100 NOT NULL
          );
        SQL
      end

      it 'does nothing' do
        recorder = nil
        expect { recorder = ActiveRecord::QueryRecorder.new { execute_service } }
          .to not_change { find_column_by(column1).default }
          .and not_change { find_column_by(column1).default_function }
          .and not_change { find_column_by(column2).default }
          .and not_change { find_column_by(column2).default_function }
        expect(recorder.log).not_to include(/ALTER TABLE/)
      end
    end

    private

    def find_column_by(name)
      connection.columns(table).find { |c| c.name == name.to_s }
    end
  end
end
