# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LooseForeignKeys do
  describe 'verify all definitions' do
    subject(:definitions) { described_class.definitions }

    it 'all definitions have assigned a known gitlab_schema and on_delete' do
      is_expected.to all(have_attributes(
                           options: a_hash_including(
                             column: be_a(String),
                             gitlab_schema: be_in(Gitlab::Database.schemas_to_base_models.symbolize_keys.keys),
                             on_delete: be_in([:async_delete, :async_nullify])
                           ),
                           from_table: be_a(String),
                           to_table: be_a(String)
                         ))
    end

    context 'ensure keys are sorted' do
      it 'does not have any keys that are out of order' do
        parsed = YAML.parse_file(described_class.loose_foreign_keys_yaml_path)
        mapping = parsed.children.first
        table_names = mapping.children.select(&:scalar?).map(&:value)
        expect(table_names).to eq(table_names.sort), "expected sorted table names in the YAML file"
      end
    end

    context 'ensure no duplicates are found' do
      it 'does not have duplicate tables defined' do
        # since we use hash to detect duplicate hash keys we need to parse YAML document
        parsed = YAML.parse_file(described_class.loose_foreign_keys_yaml_path)
        expect(parsed).to be_document
        expect(parsed.children).to be_one, "YAML has a single document"

        # require hash
        mapping = parsed.children.first
        expect(mapping).to be_mapping, "YAML has a top-level hash"

        # find all scalars with names
        table_names = mapping.children.select(&:scalar?).map(&:value)
        expect(table_names).not_to be_empty, "YAML has a non-zero tables defined"

        # expect to not have duplicates
        expect(table_names).to contain_exactly(*table_names.uniq)
      end

      it 'does not have duplicate column definitions' do
        # ignore other modifiers
        all_definitions = definitions.map do |definition|
          { from_table: definition.from_table, to_table: definition.to_table, column: definition.column }
        end

        # expect to not have duplicates
        expect(all_definitions).to contain_exactly(*all_definitions.uniq)
      end
    end

    describe 'ensuring database integrity' do
      def base_models_for(table)
        parent_table_schema = Gitlab::Database::GitlabSchema.table_schema(table)
        Gitlab::Database.schemas_to_base_models.fetch(parent_table_schema)
      end

      it 'all `to_table` tables are present', :aggregate_failures do
        definitions.each do |definition|
          base_models_for(definition.to_table).each do |model|
            expect(model.connection).to be_table_exist(definition.to_table),
              "Table #{definition.from_table} does not exist"
          end
        end
      end

      it 'all `from_table` tables are present', :aggregate_failures do
        definitions.each do |definition|
          base_models_for(definition.from_table).each do |model|
            expect(model.connection).to be_table_exist(definition.from_table),
              "Table #{definition.from_table} does not exist"
            expect(model.connection).to be_column_exist(definition.from_table, definition.column),
              "Column #{definition.column} in #{definition.from_table} does not exist"
          end
        end
      end
    end
  end
end
