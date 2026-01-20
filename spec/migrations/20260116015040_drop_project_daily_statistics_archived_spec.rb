# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DropProjectDailyStatisticsArchived, feature_category: :source_code_management do
  let(:migration) { described_class.new }
  let(:connection) { migration.connection }
  let(:table_name) { :project_daily_statistics_archived }

  describe '#up' do
    context 'when the table exists' do
      before do
        connection.execute(<<~SQL) unless connection.table_exists?(table_name)
          CREATE TABLE #{table_name} (
            id bigint NOT NULL PRIMARY KEY,
            project_id bigint NOT NULL,
            fetch_count integer NOT NULL,
            date date
          );
        SQL

        unless connection.foreign_keys(table_name).any? { |fk| fk.name == 'fk_rails_8e549b272d' }
          connection.execute(<<~SQL)
            ALTER TABLE #{table_name}
            ADD CONSTRAINT fk_rails_8e549b272d
            FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;
          SQL
        end
      end

      it 'drops the archived table' do
        expect(connection.table_exists?(table_name)).to be(true)

        migration.up

        expect(connection.table_exists?(table_name)).to be(false)
      end

      it 'removes the foreign key constraint' do
        expect(connection.foreign_keys(table_name)).not_to be_empty

        migration.up

        expect(connection.table_exists?(table_name)).to be(false)
      end
    end

    context 'when the table does not exist' do
      before do
        connection.execute("DROP TABLE IF EXISTS #{table_name}")
      end

      it 'does not raise an error' do
        expect { migration.up }.not_to raise_error
      end
    end
  end

  describe '#down' do
    before do
      # Ensure table doesn't exist before testing down
      connection.execute("DROP TABLE IF EXISTS #{table_name}")
    end

    it 'recreates the archived table with correct structure' do
      migration.down

      expect(connection.table_exists?(table_name)).to be(true)

      columns = connection.columns(table_name)
      expect(columns.map(&:name)).to contain_exactly('id', 'project_id', 'fetch_count', 'date')

      id_column = columns.find { |c| c.name == 'id' }
      expect(id_column.type).to eq(:integer)
      expect(id_column.null).to be(false)

      project_id_column = columns.find { |c| c.name == 'project_id' }
      expect(project_id_column.type).to eq(:integer)
      expect(project_id_column.null).to be(false)
    end

    it 'recreates the primary key constraint' do
      migration.down

      pk = connection.primary_key(table_name)
      expect(pk).to eq('id')
    end

    it 'recreates the indexes' do
      migration.down

      indexes = connection.indexes(table_name)
      index_names = indexes.map(&:name)

      expect(index_names).to include('index_project_daily_statistics_on_date_and_id')
      expect(index_names).to include('index_project_daily_statistics_on_project_id_and_date')
    end

    it 'recreates the foreign key to projects' do
      migration.down

      foreign_keys = connection.foreign_keys(table_name)
      fk = foreign_keys.find { |f| f.name == 'fk_rails_8e549b272d' }

      expect(fk).to be_present
      expect(fk.to_table).to eq('projects')
      expect(fk.column).to eq('project_id')
      expect(fk.on_delete).to eq(:cascade)
    end

    it 'recreates the sync trigger' do
      migration.down

      trigger_exists = connection.select_value(<<~SQL)
        SELECT 1 FROM pg_trigger
        WHERE tgname LIKE 'table_sync_trigger%'
        AND tgrelid = 'project_daily_statistics'::regclass
      SQL

      expect(trigger_exists).to eq(1)
    end
  end
end
