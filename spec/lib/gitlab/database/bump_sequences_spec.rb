# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BumpSequences, feature_category: :cell, query_analyzers: false do
  let!(:gitlab_schema) { :gitlab_main_cell }
  let!(:increment_by) { 1000 }

  let!(:main_cell_sequence_name) { 'namespaces_id_seq' }
  let!(:main_clusterwide_sequence_name) { 'users_id_seq' }
  let!(:ci_sequence_name) { 'ci_build_needs_id_seq' }

  let!(:main_sequence_name) do
    # we cannot fix a specific sequence here as we are in the process of migrating tables to either
    # gitlab_main_cell or gitlab_main_clusterwide schema.

    # Hence, we try to find any available table belonging to the `gitlab_main` schema, and use it's ID sequence.
    gitlab_main_tables = Gitlab::Database::GitlabSchema.tables_to_schema.select do |_table_name, schema_name|
      schema_name == :gitlab_main
    end.keys

    name_of_table_with_id = gitlab_main_tables.find do |table|
      model = Class.new(ApplicationRecord) do
        self.table_name = table
      end

      model.column_names.include?('id')
    end

    next unless name_of_table_with_id

    "#{name_of_table_with_id}_id_seq"
  end

  # This is just to make sure that all of the sequences start with `is_called=True`
  # which means that the next call to nextval() is going to increment the sequence.
  # To give predictable test results.
  before do
    ApplicationRecord.connection.select_value("select nextval($1)", nil, [main_cell_sequence_name])
    ApplicationRecord.connection.select_value("select nextval($1)", nil, [main_clusterwide_sequence_name])
    ApplicationRecord.connection.select_value("select nextval($1)", nil, [ci_sequence_name])
    ApplicationRecord.connection.select_value("select nextval($1)", nil, [main_sequence_name]) if main_sequence_name
  end

  describe '#execute' do
    subject { described_class.new(gitlab_schema, increment_by).execute }

    context 'when bumping the sequences' do
      it 'changes sequences by the passed argument `increase_by` value on the main database' do
        expect do
          subject
        end.to change {
          last_value_of_sequence(ApplicationRecord.connection, main_cell_sequence_name)
        }.by(1001) # the +1 is because the sequence has is_called = true
      end

      it 'will still increase the value of sequences that have is_called = False' do
        # see `is_called`: https://www.postgresql.org/docs/12/functions-sequence.html
        # choosing a new arbitrary value for the sequence
        new_value = last_value_of_sequence(ApplicationRecord.connection, main_cell_sequence_name) + 1000
        ApplicationRecord.connection.select_value(
          "select setval($1, $2, false)", nil, [main_cell_sequence_name, new_value]
        )
        expect do
          subject
        end.to change {
          last_value_of_sequence(ApplicationRecord.connection, main_cell_sequence_name)
        }.by(1000)
      end

      it 'resets the INCREMENT value of the sequences back to 1 for the following calls to nextval()' do
        subject
        value_1 = ApplicationRecord.connection.select_value("select nextval($1)", nil, [main_cell_sequence_name])
        value_2 = ApplicationRecord.connection.select_value("select nextval($1)", nil, [main_cell_sequence_name])
        expect(value_2 - value_1).to eq(1)
      end

      it 'increments the sequence of the tables in the given schema, but not in other schemas' do
        expect do
          subject
        end.to change {
          last_value_of_sequence(ApplicationRecord.connection, main_cell_sequence_name)
        }.by(1001)
        .and change {
          last_value_of_sequence(ApplicationRecord.connection, main_clusterwide_sequence_name)
        }.by(0)
        .and change {
          last_value_of_sequence(ApplicationRecord.connection, ci_sequence_name)
        }.by(0)
      end

      it 'increments the sequence of the tables in the given schema, but not in gitlab_main' do
        if main_sequence_name
          expect do
            subject
          end.to change {
            last_value_of_sequence(ApplicationRecord.connection, main_cell_sequence_name)
          }.by(1001)
          .and change {
            last_value_of_sequence(ApplicationRecord.connection, main_sequence_name)
          }.by(0)
        end
      end
    end
  end

  private

  def last_value_of_sequence(connection, sequence_name)
    allow_cross_joins_across_databases(url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/408220') do
      connection.select_value("select last_value from #{sequence_name}")
    end
  end
end
