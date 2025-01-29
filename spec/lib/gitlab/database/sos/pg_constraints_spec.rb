# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Sos::PgConstraints, feature_category: :database do
  describe '#run' do
    let(:temp_directory) { Dir.mktmpdir }
    let(:output_file_path) { temp_directory }
    let(:expected_file_path) { File.join(output_file_path, 'pg_constraints.csv') }
    let(:output) { Gitlab::Database::Sos::Output.new(output_file_path, mode: :directory) }

    after do
      FileUtils.remove_entry(temp_directory)
    end

    it 'creates a CSV file with the correct headers and data (if applicable)' do
      described_class.run(output)
      output.finish

      expect(File.exist?(expected_file_path)).to be true

      csv_content = CSV.read(expected_file_path)

      expect(csv_content.first).to eq(%w[table_name constraint_name constraint_definition])
    end
  end
end
