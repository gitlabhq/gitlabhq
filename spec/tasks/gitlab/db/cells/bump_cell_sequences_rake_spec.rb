# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:db:cells:bump_cell_sequences', :silence_stdout,
  :suppress_gitlab_schemas_validate_connection, feature_category: :cell, query_analyzers: false do
  before(:all) do
    Rake.application.rake_require 'tasks/gitlab/db/cells/bump_cell_sequences'
  end

  let(:main_sequence_name) { 'users_id_seq' }
  let(:main_cell_sequence_name) { 'namespaces_id_seq' }

  # This is just to make sure that all of the sequences start with `is_called=True`
  # which means that the next call to nextval() is going to increment the sequence.
  # To give predictable test results.
  before do
    ApplicationRecord.connection.select_value("select nextval($1)", nil, [main_cell_sequence_name])
  end

  context 'when run in production environment' do
    let(:expected_error_message) do
      <<~HEREDOC
        This rake task cannot be run in production environment
      HEREDOC
    end

    it 'will print error message and exit' do
      allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)

      expect do
        run_rake_task('gitlab:db:cells:bump_cell_sequences', '10')
      end.to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
      .and output(expected_error_message).to_stdout
    end
  end

  context 'when passing wrong argument' do
    let(:expected_error_message) do
      <<~HEREDOC
        Please specify a positive integer `increase_by` value
        Example: rake gitlab:db:cells:bump_cell_sequences[100000]
      HEREDOC
    end

    it 'will print an error message and exit when passing no argument' do
      expect do
        run_rake_task('gitlab:db:cells:bump_cell_sequences')
      end.to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
      .and output(expected_error_message).to_stdout
    end

    it 'will print an error message and exit when passing a non positive integer value' do
      expect do
        run_rake_task('gitlab:db:cells:bump_cell_sequences', '-5')
      end.to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
      .and output(expected_error_message).to_stdout
    end
  end

  context 'when bumping the sequences' do
    it 'increments the sequence of the tables in the given schema, but not in other schemas' do
      expect do
        run_rake_task('gitlab:db:cells:bump_cell_sequences', '10')
      end.to change {
        last_value_of_sequence(ApplicationRecord.connection, main_sequence_name)
      }.by(0)
      .and change {
        last_value_of_sequence(ApplicationRecord.connection, main_cell_sequence_name)
      }.by(11) # the +1 is because the sequence has is_called = true
    end
  end
end

def last_value_of_sequence(connection, sequence_name)
  allow_cross_joins_across_databases(url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/408220') do
    connection.select_value("select last_value from #{sequence_name}")
  end
end
