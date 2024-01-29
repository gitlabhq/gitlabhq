# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SwapColumnsForSystemNoteMetadataId, feature_category: :team_planning do
  describe '#up' do
    let(:pk_name) { "system_note_metadata_pkey" }
    let(:fk_name) { "fk_2a039c40f4" } # FK on 'resource_link_events'

    before do
      # A we call `schema_migrate_down!` before each example, and for this migration
      # `#down` is same as `#up`, we need to ensure we start from the expected state.
      connection = described_class.new.connection
      connection.execute('ALTER TABLE system_note_metadata ALTER COLUMN id TYPE integer')
      connection.execute('ALTER TABLE system_note_metadata ALTER COLUMN id_convert_to_bigint TYPE bigint')
    end

    it 'swaps the integer and bigint columns with correct constraint names' do
      table = table(:system_note_metadata)

      disable_migrations_output do
        reversible_migration do |migration|
          migration.before -> {
            table.reset_column_information

            primary_key_naming_check = query_constraint_by_name(:system_note_metadata, pk_name).first
            foreign_key_naming_check = query_constraint_by_name(:resource_link_events, fk_name).first
            expect(primary_key_naming_check).to match("constraint_exists" => true)
            expect(foreign_key_naming_check).to match("constraint_exists" => true)
            expect(table.columns.find { |c| c.name == 'id' }.sql_type).to eq('integer')
            expect(table.columns.find { |c| c.name == 'id_convert_to_bigint' }.sql_type).to eq('bigint')
          }

          migration.after -> {
            table.reset_column_information

            primary_key_naming_check = query_constraint_by_name(:system_note_metadata, pk_name).first
            foreign_key_naming_check = query_constraint_by_name(:resource_link_events, fk_name).first
            expect(primary_key_naming_check).to match("constraint_exists" => true)
            expect(foreign_key_naming_check).to match("constraint_exists" => true)
            expect(table.columns.find { |c| c.name == 'id' }.sql_type).to eq('bigint')
            expect(table.columns.find { |c| c.name == 'id_convert_to_bigint' }.sql_type).to eq('integer')
          }
        end
      end
    end

    def query_constraint_by_name(table_name, conname)
      described_class.new.connection.execute <<~SQL
        SELECT true as constraint_exists FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid
        WHERE t.relname = \'#{table_name}\' AND c.conname = \'#{conname}\';
      SQL
    end
  end
end
