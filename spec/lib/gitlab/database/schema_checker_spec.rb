# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SchemaChecker, feature_category: :database do
  let(:database_name) { 'main' }
  let(:structure_sql_path) { Rails.root.join('db/structure.sql') }
  let(:connection) do
    instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter,
      class: ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
  end

  let(:database_source) { Gitlab::Schema::Validation::Sources::Database.new(connection) }
  let(:structure_sql_source) { instance_double(Gitlab::Schema::Validation::Sources::StructureSql) }

  let(:missing_tables_validator) { instance_double(Gitlab::Schema::Validation::Validators::MissingTables) }
  let(:missing_indexes_validator) { instance_double(Gitlab::Schema::Validation::Validators::MissingIndexes) }
  let(:missing_foreign_keys_validator) { instance_double(Gitlab::Schema::Validation::Validators::MissingForeignKeys) }
  let(:missing_sequences_validator) { instance_double(Gitlab::Schema::Validation::Validators::MissingSequences) }
  let(:different_sequences_validator) do
    instance_double(Gitlab::Schema::Validation::Validators::DifferentSequenceOwners)
  end

  # rubocop:disable RSpec/VerifiedDoubles -- It is simpler to test than to use the SchemaObject types
  let(:missing_tables) { [double(object_name: 'users', details: {}), double(object_name: 'projects', details: {})] }
  let(:missing_indexes) { [double(object_name: 'index_users_on_email', details: {})] }
  let(:missing_foreign_keys) { [double(object_name: 'fk_projects_namespace_id', details: {})] }
  let(:missing_sequences) { [] }
  let(:wrong_sequence_owners) do
    [double(object_name: 'some_sequence', details: { current_owner: 'public', expected_owner: 'another_schema' })]
  end
  # rubocop:enable RSpec/VerifiedDoubles

  subject(:checker) { described_class.new(database_name: database_name) }

  before do
    allow(Gitlab::Schema::Validation::Sources::Database).to receive(:new)
      .and_return(database_source)
    allow(Gitlab::Schema::Validation::Sources::StructureSql).to receive(:new)
      .with(structure_sql_path).and_return(structure_sql_source)

    allow(Gitlab::Schema::Validation::Validators::MissingTables).to receive(:new)
      .with(structure_sql_source, database_source).and_return(missing_tables_validator)
    allow(Gitlab::Schema::Validation::Validators::MissingIndexes).to receive(:new)
      .with(structure_sql_source, database_source).and_return(missing_indexes_validator)
    allow(Gitlab::Schema::Validation::Validators::MissingForeignKeys).to receive(:new)
      .with(structure_sql_source, database_source).and_return(missing_foreign_keys_validator)
    allow(Gitlab::Schema::Validation::Validators::MissingSequences).to receive(:new)
      .with(structure_sql_source, database_source).and_return(missing_sequences_validator)
    allow(Gitlab::Schema::Validation::Validators::DifferentSequenceOwners).to receive(:new)
      .with(structure_sql_source, database_source).and_return(different_sequences_validator)

    allow(missing_tables_validator).to receive(:execute).and_return(missing_tables)
    allow(missing_indexes_validator).to receive(:execute).and_return(missing_indexes)
    allow(missing_foreign_keys_validator).to receive(:execute).and_return(missing_foreign_keys)
    allow(missing_sequences_validator).to receive(:execute).and_return(missing_sequences)
    allow(different_sequences_validator).to receive(:execute).and_return(wrong_sequence_owners)
  end

  describe '#initialize' do
    context 'with invalid database name' do
      let(:invalid_database_name) { 'invalid_db' }

      it 'raises an error' do
        expect do
          described_class.new(database_name: invalid_database_name)
        end.to raise_error("Invalid database name: #{invalid_database_name}")
      end
    end
  end

  describe '#execute', :freeze_time do
    it 'returns the expected schema check results structure' do
      result = checker.execute

      expect(result).to eq({
        schema_check_results: {
          database_name => {
            missing_tables: [
              { name: 'users' },
              { name: 'projects' }
            ],
            missing_indexes: [
              { name: 'index_users_on_email' }
            ],
            missing_foreign_keys: [
              { name: 'fk_projects_namespace_id' }
            ],
            missing_sequences: [],
            wrong_sequence_owners: [
              {
                details: {
                  current_owner: "public",
                  expected_owner: "another_schema"
                },
                name: "some_sequence"
              }
            ]
          }
        },
        metadata: {
          last_run_at: Time.current.iso8601
        }
      })
    end

    context 'when there are no inconsistencies' do
      let(:missing_tables) { [] }
      let(:missing_indexes) { [] }
      let(:missing_foreign_keys) { [] }
      let(:missing_sequences) { [] }
      let(:wrong_sequence_owners) { [] }

      it 'returns empty arrays for all inconsistency types' do
        result = checker.execute

        expect(result[:schema_check_results][database_name]).to eq({
          missing_tables: [],
          missing_indexes: [],
          missing_foreign_keys: [],
          missing_sequences: [],
          wrong_sequence_owners: []
        })
      end
    end

    context 'with different database name' do
      let(:database_name) { 'ci' }

      before do
        skip_if_shared_database(:ci)
      end

      it 'includes the correct database name in results' do
        result = checker.execute

        expect(result[:schema_check_results]).to have_key('ci')
        expect(result[:schema_check_results]['ci']).to be_a(Hash)
      end
    end
  end
end
