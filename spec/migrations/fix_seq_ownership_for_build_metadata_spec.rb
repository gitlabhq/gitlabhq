# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FixSeqOwnershipForBuildMetadata, :migration, feature_category: :continuous_integration do
  let(:migration) { described_class.new }

  describe '#up' do
    let(:sequence) { 'bulk_import_configurations_id_seq' }
    let(:sequence_two) { 'board_labels_id_seq' }

    before do
      execute_sql(<<-SQL)
        ALTER SEQUENCE #{sequence} OWNED BY p_ci_builds_metadata.id;
        ALTER SEQUENCE #{sequence_two} OWNED BY ci_builds_metadata.id;
      SQL
    end

    after do
      execute_sql(<<-SQL)
        ALTER SEQUENCE #{sequence} OWNED BY bulk_import_configurations.id;
        ALTER SEQUENCE #{sequence_two} OWNED BY board_labels.id;
      SQL
    end

    it 'fixes sequence ownership', :aggregate_failures do
      # Verify initial state
      expect(sequence_owner(sequence)).to eq('p_ci_builds_metadata.id')
      expect(sequence_owner(sequence_two)).to eq('ci_builds_metadata.id')

      migration.up

      # Verify sequence ownership has been corrected
      expect(sequence_owner(sequence)).to eq('bulk_import_configurations.id')
      expect(sequence_owner(sequence_two)).to eq('board_labels.id')
    end

    it 'does not modify sequences not owned by ci_builds_metadata or p_ci_builds_metadata', :aggregate_failures do
      execute_sql('DROP SEQUENCE IF EXISTS unrelated_seq;')
      execute_sql('CREATE SEQUENCE unrelated_seq;')
      execute_sql(<<-SQL)
        ALTER SEQUENCE #{sequence} OWNED BY abuse_reports.id;
      SQL

      expect { migration.up }.not_to change { sequence_owner('unrelated_seq') }
      expect(sequence_owner(sequence)).to eq('abuse_reports.id')

      execute_sql('DROP SEQUENCE unrelated_seq;')
    end

    it 'ignores unknown sequences', :aggregate_failures do
      execute_sql('DROP SEQUENCE IF EXISTS unknown_seq;')
      execute_sql('CREATE SEQUENCE unknown_seq;')
      execute_sql(<<-SQL)
        ALTER SEQUENCE unknown_seq OWNED BY ci_builds_metadata.id;
      SQL

      expect { migration.up }.not_to change { sequence_owner('unknown_seq') }

      execute_sql 'DROP SEQUENCE unknown_seq;'
    end
  end

  def sequence_owner(sequence_name)
    result = ApplicationRecord.connection.select_one(<<-SQL, nil, [sequence_name])
      SELECT n.nspname AS schema_name,
             t.relname AS table_name,
             a.attname AS column_name
      FROM pg_class s
      JOIN pg_depend d ON d.objid = s.oid
      AND d.classid = 'pg_class'::regclass
      AND d.refclassid = 'pg_class'::regclass
      JOIN pg_class t ON t.oid = d.refobjid
      JOIN pg_attribute a ON a.attrelid = t.oid
      AND a.attnum = d.refobjsubid
      JOIN pg_namespace n ON n.oid = s.relnamespace
      WHERE s.relkind = 'S'
        AND s.relname = $1
    SQL

    return unless result

    "#{result['table_name']}.#{result['column_name']}"
  end

  def execute_sql(sql)
    ApplicationRecord.connection.execute(sql)
  end
end
