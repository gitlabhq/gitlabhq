# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:db:decomposition:rollback:bump_ci_sequences', :silence_stdout,
  :suppress_gitlab_schemas_validate_connection, feature_category: :cell, query_analyzers: false do
  before(:all) do
    Rake.application.rake_require 'tasks/gitlab/db/decomposition/rollback/bump_ci_sequences'
  end

  let(:expected_error_message) do
    <<-EOS.strip_heredoc
      Please specify a positive integer `increase_by` value
      Example: rake gitlab:db:decomposition:rollback:bump_ci_sequences[100000]
    EOS
  end

  let(:main_sequence_name) { 'issues_id_seq' }
  let(:ci_sequence_name) { 'ci_build_needs_id_seq' }

  # This is just to make sure that all of the sequences start with `is_called=True`
  # which means that the next call to nextval() is going to increment the sequence.
  # To give predictable test results.
  before do
    ApplicationRecord.connection.select_value("select nextval($1)", nil, [ci_sequence_name])
  end

  context 'when passing wrong argument' do
    it 'will print an error message and exit when passing no argument' do
      expect do
        run_rake_task('gitlab:db:decomposition:rollback:bump_ci_sequences')
      end.to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
      .and output(expected_error_message).to_stdout
    end

    it 'will print an error message and exit when passing a non positive integer value' do
      expect do
        run_rake_task('gitlab:db:decomposition:rollback:bump_ci_sequences', '-5')
      end.to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
      .and output(expected_error_message).to_stdout
    end
  end

  context 'when bumping the ci sequences' do
    it 'changes ci sequences by the passed argument `increase_by` value on the main database' do
      expect do
        run_rake_task('gitlab:db:decomposition:rollback:bump_ci_sequences', '15')
      end.to change {
        last_value_of_sequence(ApplicationRecord.connection, ci_sequence_name)
      }.by(16) # the +1 is because the sequence has is_called = true
    end

    it 'will still increase the value of sequences that have is_called = False' do
      # see `is_called`: https://www.postgresql.org/docs/12/functions-sequence.html
      # choosing a new arbitrary value for the sequence
      new_value = last_value_of_sequence(ApplicationRecord.connection, ci_sequence_name) + 1000
      ApplicationRecord.connection.select_value("select setval($1, $2, false)", nil, [ci_sequence_name, new_value])
      expect do
        run_rake_task('gitlab:db:decomposition:rollback:bump_ci_sequences', '15')
      end.to change {
        last_value_of_sequence(ApplicationRecord.connection, ci_sequence_name)
      }.by(15)
    end

    it 'resets the INCREMENT value of the sequences back to 1 for the following calls to nextval()' do
      run_rake_task('gitlab:db:decomposition:rollback:bump_ci_sequences', '15')
      value_1 = ApplicationRecord.connection.select_value("select nextval($1)", nil, [ci_sequence_name])
      value_2 = ApplicationRecord.connection.select_value("select nextval($1)", nil, [ci_sequence_name])
      expect(value_2 - value_1).to eq(1)
    end

    it 'does not change the sequences on the gitlab_main tables' do
      expect do
        run_rake_task('gitlab:db:decomposition:rollback:bump_ci_sequences', '10')
      end.to change {
        last_value_of_sequence(ApplicationRecord.connection, main_sequence_name)
      }.by(0)
      .and change {
        last_value_of_sequence(ApplicationRecord.connection, ci_sequence_name)
      }.by(11) # the +1 is because the sequence has is_called = true
    end
  end

  context 'when multiple databases' do
    before do
      skip_if_shared_database(:ci)
    end

    it 'does not change ci sequences on the ci database' do
      expect do
        run_rake_task('gitlab:db:decomposition:rollback:bump_ci_sequences', '10')
      end.to change {
        last_value_of_sequence(Ci::ApplicationRecord.connection, ci_sequence_name)
      }.by(0)
    end
  end
end

def last_value_of_sequence(connection, sequence_name)
  allow_cross_joins_across_databases(url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/408220') do
    connection.select_value("select last_value from #{sequence_name}")
  end
end
