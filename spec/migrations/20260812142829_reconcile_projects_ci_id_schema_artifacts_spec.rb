# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ReconcileProjectsCiIdSchemaArtifacts, feature_category: :database do
  let(:migration) { described_class.new }
  let(:connection) { migration.connection }

  describe '#up' do
    context 'when the column and index are absent (canonical/clean installation)' do
      before do
        connection.execute('DROP INDEX IF EXISTS index_projects_on_ci_id')
        connection.execute('ALTER TABLE projects DROP COLUMN IF EXISTS ci_id')
      end

      it 'is a no-op and does not raise an error' do
        expect { migrate! }.not_to raise_error
      end

      it 'leaves the projects table unchanged' do
        expect(connection.column_exists?(:projects, :ci_id)).to be(false)
        expect(migration.index_exists_by_name?(:projects, 'index_projects_on_ci_id')).to be(false)

        migrate!

        expect(connection.column_exists?(:projects, :ci_id)).to be(false)
        expect(migration.index_exists_by_name?(:projects, 'index_projects_on_ci_id')).to be(false)
      end
    end

    context 'when the column and index are present (drift scenario)' do
      before do
        unless connection.column_exists?(:projects, :ci_id)
          connection.execute('ALTER TABLE projects ADD COLUMN ci_id integer')
        end

        unless migration.index_exists_by_name?(:projects, 'index_projects_on_ci_id')
          connection.execute('CREATE INDEX index_projects_on_ci_id ON projects (ci_id)')
        end
      end

      after do
        connection.execute('DROP INDEX IF EXISTS index_projects_on_ci_id')
        connection.execute('ALTER TABLE projects DROP COLUMN IF EXISTS ci_id')
      end

      it 'removes the index' do
        expect(migration.index_exists_by_name?(:projects, 'index_projects_on_ci_id')).to be(true)

        migrate!

        expect(migration.index_exists_by_name?(:projects, 'index_projects_on_ci_id')).to be(false)
      end

      it 'removes the column' do
        expect(connection.column_exists?(:projects, :ci_id)).to be(true)

        migrate!

        expect(connection.column_exists?(:projects, :ci_id)).to be(false)
      end
    end
  end

  describe '#down' do
    it 'does not change the column or index state' do
      expect(connection.column_exists?(:projects, :ci_id)).to be(false)
      expect(migration.index_exists_by_name?(:projects, 'index_projects_on_ci_id')).to be(false)

      migration.down

      expect(connection.column_exists?(:projects, :ci_id)).to be(false)
      expect(migration.index_exists_by_name?(:projects, 'index_projects_on_ci_id')).to be(false)
    end
  end
end
