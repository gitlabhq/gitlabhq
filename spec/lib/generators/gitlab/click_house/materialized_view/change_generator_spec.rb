# frozen_string_literal: true

require 'spec_helper'
require 'generators/gitlab/click_house/materialized_view/change_generator'
require 'fileutils'

RSpec.describe Gitlab::ClickHouse::MaterializedView::ChangeGenerator, feature_category: :database do
  let(:view_name) { 'test_view' }
  let(:migration_name) { view_name }
  let(:destination_root) { Dir.mktmpdir }
  let(:db_migrate_path) { 'db/click_house/migrate/main' }
  let(:click_house_connection) { instance_double(ClickHouse::Connection, database_name: 'main') }

  subject(:generator) { described_class.new([migration_name]) }

  before do
    generator.destination_root = destination_root
    allow(generator).to receive(:connection).and_return(click_house_connection)

    FileUtils.mkdir_p(File.join(destination_root, db_migrate_path))
  end

  describe '#old_materialized_view_query' do
    context 'when materialized view cannot be found' do
      before do
        allow(click_house_connection).to receive(:select).and_return([])
      end

      it 'raises error' do
        expect { generator.send(:old_materialized_view_query, view_name) }
          .to raise_error("Couldn't find materialized view 'test_view'")
      end
    end

    context 'when materialized view exists' do
      let(:statement) { "CREATE MATERIALIZED VIEW test_view ENGINE = Memory AS SELECT * FROM table" }
      let(:rows) { [{ 'statement' => statement }] }

      before do
        allow(click_house_connection).to receive(:select).and_return(rows)
      end

      it 'returns the inner query' do
        expect(generator.send(:old_materialized_view_query, view_name)).to eq('SELECT * FROM table')
      end

      it 'handles multiline statements' do
        multiline_statement = <<~SQL
          CREATE MATERIALIZED VIEW test_view
          AS
          SELECT *
          FROM table
        SQL
        allow(click_house_connection).to receive(:select).and_return([{ 'statement' => multiline_statement }])

        expect(generator.send(:old_materialized_view_query, view_name)).to eq("SELECT *\nFROM table\n")
      end
    end
  end

  describe '#create_migration_file' do
    let(:statement) { "CREATE MATERIALIZED VIEW test_view AS SELECT 1\nFROM table" }
    let(:rows) { [{ 'statement' => statement }] }

    before do
      allow(Time).to receive_message_chain(:current, :strftime).and_return('20230101000000')
    end

    context 'when materialized view exists' do
      before do
        allow(click_house_connection).to receive(:select).and_return(rows)
      end

      it 'generates a migration with the correct content' do
        generator.invoke_all

        migration_file = Dir.glob(File.join(destination_root, db_migrate_path,
          "*_change_materialized_view_test_view.rb")).first
        expect(migration_file).not_to be_nil

        content = File.read(migration_file)
        expect(content).to include('class ChangeMaterializedViewTestView < ClickHouse::Migration')
        expect(content).to include('ALTER TABLE test_view MODIFY QUERY')
        expect(content).to include('SELECT 1')
        expect(content).to include('FROM table')
      end

      context 'when multiple versions exist' do
        it 'increments the version suffix' do
          allow(generator).to receive(:number_of_rebuilds).and_return(1)

          generator.invoke_all

          migration_file = Dir.glob(File.join(destination_root, db_migrate_path,
            "*_change_materialized_view_test_view_v2.rb")).first
          expect(migration_file).not_to be_nil
        end

        it 'increments the version suffix further' do
          allow(generator).to receive(:number_of_rebuilds).and_return(2)

          generator.invoke_all

          migration_file = Dir.glob(File.join(destination_root, db_migrate_path,
            "*_change_materialized_view_test_view_v3.rb")).first
          expect(migration_file).not_to be_nil
        end
      end
    end
  end
end
