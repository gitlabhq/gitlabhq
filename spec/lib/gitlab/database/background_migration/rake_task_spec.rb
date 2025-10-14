# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundMigration::RakeTask, feature_category: :database do
  subject(:task) { Class.new.extend(described_class) }

  describe '#connection_and_id_from_params' do
    it 'returns connection and id for the migration' do
      # rubocop:disable RSpec/VerifiedDoubles -- n/a
      conn = double
      model = double(connection: conn)
      # rubocop:enable RSpec/VerifiedDoubles

      expect(Gitlab::Database).to receive(:database_base_models).and_return({ 'main' => model })

      expect(task.connection_and_id_from_params('main_9')).to eq([conn, 9])
    end
  end

  describe '#print_table' do
    it 'returns nil when data is nil' do
      expect(task.print_table(nil)).to be_nil
    end

    it 'returns nil when data is empty array' do
      expect(task.print_table([])).to be_nil
    end

    it 'prints provided data as a table with headers' do
      data = [
        %w[id table_name job_class_name],
        %w[main_1 namespace_settings UpdateRequireDpopForManageApiEndpointsToFalse],
        %w[main_11 timelogs FixNonExistingTimelogUsers]
      ]

      # rubocop:disable Layout/TrailingWhitespace -- The trailing whitespace is needed
      expected = <<~TABLE

      id      | table_name         | job_class_name                               
      --------|--------------------|----------------------------------------------
      main_1  | namespace_settings | UpdateRequireDpopForManageApiEndpointsToFalse
      main_11 | timelogs           | FixNonExistingTimelogUsers                   

      TABLE
      # rubocop:enable Layout/TrailingWhitespace

      expect { task.print_table(data) }.to output(expected).to_stdout
    end

    it 'prints provided data as a table without headers when asked' do
      data = [
        %w[main_1 namespace_settings UpdateRequireDpopForManageApiEndpointsToFalse],
        %w[main_11 timelogs FixNonExistingTimelogUsers]
      ]

      # rubocop:disable Layout/TrailingWhitespace -- The trailing whitespace is needed
      expected = <<~TABLE

      main_1  | namespace_settings | UpdateRequireDpopForManageApiEndpointsToFalse
      main_11 | timelogs           | FixNonExistingTimelogUsers                   

      TABLE
      # rubocop:enable Layout/TrailingWhitespace

      expect { task.print_table(data, headers: false) }.to output(expected).to_stdout
    end
  end
end
