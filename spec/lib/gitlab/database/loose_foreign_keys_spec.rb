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

    describe 'ensuring database integrity' do
      def base_models_for(table)
        parent_table_schema = Gitlab::Database::GitlabSchema.table_schema(table)
        Gitlab::Database.schemas_to_base_models.fetch(parent_table_schema)
      end

      it 'all `to_table` tables are present' do
        definitions.each do |definition|
          base_models_for(definition.to_table).each do |model|
            expect(model.connection).to be_table_exist(definition.to_table)
          end
        end
      end

      it 'all `from_table` tables are present' do
        definitions.each do |definition|
          base_models_for(definition.from_table).each do |model|
            expect(model.connection).to be_table_exist(definition.from_table)
            expect(model.connection).to be_column_exist(definition.from_table, definition.column)
          end
        end
      end
    end
  end
end
