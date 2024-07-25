# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FixSequenceOwnersForCiBuilds, :migration, feature_category: :continuous_integration do
  let(:migration) { described_class.new }

  describe '#up' do
    let(:sequence) { "upload_states_upload_id_seq" }
    let(:sequence_two) { "board_labels_id_seq" }

    before do
      ApplicationRecord.connection.execute(<<-SQL)
        ALTER SEQUENCE #{sequence} OWNED BY p_ci_builds.id;
        ALTER SEQUENCE #{sequence_two} OWNED BY ci_builds.id;
      SQL
    end

    after do
      ApplicationRecord.connection.execute(<<-SQL)
        ALTER SEQUENCE #{sequence} OWNED BY upload_states.upload_id;
        ALTER SEQUENCE #{sequence_two} OWNED BY board_labels.id;
      SQL
    end

    it 'fixes sequence ownership', :aggregate_failures do
      # Verify initial state
      expect(sequence_owner(sequence)).to eq('p_ci_builds.id')
      expect(sequence_owner(sequence_two)).to eq('ci_builds.id')

      migration.up

      # Verify sequence ownership has been corrected
      expect(sequence_owner(sequence)).to eq('upload_states.upload_id')
      expect(sequence_owner(sequence_two)).to eq('board_labels.id')
    end

    it 'does not modify sequences not owned by ci_builds or p_ci_builds', :aggregate_failures do
      ApplicationRecord.connection.execute('DROP SEQUENCE IF EXISTS unrelated_seq;')
      ApplicationRecord.connection.execute('CREATE SEQUENCE unrelated_seq;')
      ApplicationRecord.connection.execute(<<-SQL)
        ALTER SEQUENCE #{sequence} OWNED BY abuse_reports.id;
      SQL

      expect { migration.up }.not_to change { sequence_owner('unrelated_seq') }
      expect(sequence_owner(sequence)).to eq('abuse_reports.id')

      ApplicationRecord.connection.execute('DROP SEQUENCE unrelated_seq;')
    end

    it 'ignores unknown sequences', :aggregate_failures do
      ApplicationRecord.connection.execute('DROP SEQUENCE IF EXISTS unknown_seq;')
      ApplicationRecord.connection.execute('CREATE SEQUENCE unknown_seq;')
      ApplicationRecord.connection.execute(<<-SQL)
        ALTER SEQUENCE unknown_seq OWNED BY ci_builds.id;
      SQL

      expect { migration.up }.not_to change { sequence_owner('unknown_seq') }

      ApplicationRecord.connection.execute('DROP SEQUENCE unknown_seq;')
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
end
