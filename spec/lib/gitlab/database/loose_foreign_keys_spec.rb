# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LooseForeignKeys, feature_category: :database do
  describe 'verify all definitions' do
    subject(:definitions) { described_class.definitions }

    it 'all definitions have assigned a known gitlab_schema and on_delete' do
      is_expected.to all(
        have_attributes(
          options: a_hash_including(
            column: be_a(String),
            gitlab_schema: be_in(Gitlab::Database.schemas_to_base_models.symbolize_keys.keys),
            on_delete: be_in([:async_delete, :async_nullify, :update_column_to]),
            target_column: be_a(String).or(be_a(NilClass)),
            target_value: be_a(String).or(be_a(Integer)).or(be_a(NilClass)),
            delete_limit: be_a(Integer).or(be_a(NilClass)),
            conditions: be_nil.or(
              be_an(Array).and(
                all(
                  a_hash_including(
                    column: be_a(String),
                    value: be_a(String).or(be_a(Integer))
                  )
                )
              )
            )
          ),
          from_table: be_a(String),
          to_table: be_a(String)
        )
      )
    end

    context 'ensure keys are sorted' do
      it 'does not have any keys that are out of order' do
        parsed = YAML.parse_file(described_class.loose_foreign_keys_yaml_path)
        mapping = parsed.children.first
        table_names = mapping.children.select(&:scalar?).map(&:value)
        expect(table_names).to eq(table_names.sort),
          "expected sorted table names in the YAML file #{described_class.loose_foreign_keys_yaml_path}"
      end
    end

    context 'ensure no partitions are included' do
      let(:all_source_tables) do
        YAML
        .load_file(described_class.loose_foreign_keys_yaml_path)
        .values.flat_map { |sources| sources.pluck(:table) }
        .uniq
      end

      let(:included_partitioned_tables) do
        Gitlab::Database::PostgresPartition.where(name: all_source_tables)
      end

      it 'does not include partitions as source tables' do
        expect(included_partitioned_tables).to be_blank, <<~END
          Please remove these partitions #{included_partitioned_tables.map(&:name).join(', ')}.
          And include their partitioned tables #{included_partitioned_tables.map(&:parent_identifier)} instead
          if you haven't done so.
        END
      end
    end

    context 'for all partitioned tables' do
      let(:tables_with_trigger) do
        Gitlab::Database::PostgresPartitionedTable
          .connection.select_values(<<~SQL)
            SELECT event_object_table
            FROM information_schema.triggers
            WHERE action_statement LIKE '%insert_into_loose_foreign_keys_deleted_records_override_table%'
          SQL
      end

      let(:partitioned_tables_without_trigger) do
        partitioned_tables
        .pluck(:name)
        .reject { |table| tables_with_trigger.include?(table) }
      end

      let(:partitioned_tables) do
        Gitlab::Database::PostgresPartitionedTable.where(name: all_source_tables)
      end

      let(:all_source_tables) do
        YAML
        .load_file(described_class.loose_foreign_keys_yaml_path)
        .values.flat_map { |sources| sources.pluck(:table) }
        .uniq
      end

      it 'has installed trigger for all partitioned tables' do
        expect(partitioned_tables_without_trigger).to be_blank, <<~END
          #{partitioned_tables_without_trigger.join(',')} need(s) LFK trigger.
          Please create migration using `track_record_deletions_override_table_name` to install the trigger.
        END
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
          {
            from_table: definition.from_table,
            to_table: definition.to_table,
            column: definition.column,
            target_column: definition.options[:target_column],
            target_value: definition.options[:target_value]
          }
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

            if definition.options[:target_column]
              expect(model.connection).to be_column_exist(definition.from_table, definition.options[:target_column]),
                "Column #{definition.options[:target_column]} in #{definition.from_table} does not exist"
            end
          end
        end
      end

      it 'ensures that async_nullify does not conflict with not-null constraints' do
        definitions
          .filter { |definition| definition.on_delete == :async_nullify }
          .each do |definition|
            base_models_for(definition.from_table).each do |model|
              nullable =
                model.connection
                  .select_value(<<~SQL, 'NULLABLE', [definition.from_table, definition.column])
                    SELECT
                      CASE
                        WHEN a.attnotnull THEN false -- column is not-null
                        WHEN c.contype = 'c' AND pg_get_constraintdef(c.oid) LIKE '%IS NOT NULL%' THEN false -- not-null constraint check
                        WHEN c.contype = 'p' THEN false -- part of primary key constraint
                        ELSE true
                      END AS nullable
                    FROM pg_attribute a
                    LEFT JOIN pg_constraint c ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
                    JOIN pg_class t ON a.attrelid = t.oid
                    JOIN pg_namespace s ON t.relnamespace = s.oid
                    WHERE
                      s.nspname = current_schema()
                      AND t.relname = $1
                      AND a.attname = $2
                      AND a.attnum > 0 -- non-system column
                      AND NOT a.attisdropped -- non-dropped column
                    LIMIT 1;
                  SQL

              expect(nullable).to be_truthy, <<~ERROR
                Column `#{definition.from_table}.#{definition.column}` is not-nullable,
                and this conflicts with `on_delete: async_nullify`.
              ERROR
            end
          end
      end
    end
  end

  context 'all tables have correct triggers installed' do
    let(:all_tables_from_yaml) { described_class.definitions.pluck(:to_table).uniq }

    let(:all_tables_with_triggers) do
      triggers_query = <<~SQL
        SELECT event_object_table FROM information_schema.triggers
        WHERE trigger_name LIKE '%_loose_fk_trigger'
      SQL

      ApplicationRecord.connection.execute(triggers_query)
        .pluck('event_object_table').uniq
    end

    it 'all YAML tables do have `track_record_deletions` installed' do
      missing_trigger_tables = all_tables_from_yaml - all_tables_with_triggers

      expect(missing_trigger_tables).to be_empty, <<~END
        The loose foreign keys definitions require using `track_record_deletions`
        for the following tables: #{missing_trigger_tables}.
        Read more at https://docs.gitlab.com/ee/development/database/loose_foreign_keys.html."
      END
    end

    it 'no extra tables have `track_record_deletions` installed' do
      extra_trigger_tables = all_tables_with_triggers - all_tables_from_yaml

      pending 'This result of this test is informatory, and not critical' if extra_trigger_tables.any?

      expect(extra_trigger_tables).to be_empty, <<~END
        The following tables have unused `track_record_deletions` triggers installed,
        but they are not referenced by any of the loose foreign key definitions: #{extra_trigger_tables}.
        You can remove them in one of the future releases as part of `db/post_migrate`.
        Read more at https://docs.gitlab.com/ee/development/database/loose_foreign_keys.html."
      END
    end
  end

  describe '.build_definition' do
    context 'when child table schema is not defined' do
      let(:loose_foreign_keys_yaml) do
        {
          'ci_unknown_table' => [
            {
              'table' => 'projects',
              'column' => 'project_id',
              'on_delete' => 'async_delete'
            }
          ]
        }
      end

      subject { described_class.definitions }

      before do
        described_class.instance_variable_set(:@definitions, nil)
        described_class.instance_variable_set(:@loose_foreign_keys_yaml, loose_foreign_keys_yaml)
      end

      after do
        described_class.instance_variable_set(:@loose_foreign_keys_yaml, nil)
      end

      it 'raises Gitlab::Database::GitlabSchema::UnknownSchemaError error' do
        expect { subject }.to raise_error(Gitlab::Database::GitlabSchema::UnknownSchemaError)
      end
    end
  end
end
