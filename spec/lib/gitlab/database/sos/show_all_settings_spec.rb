# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Sos::ShowAllSettings, feature_category: :database do
  describe '#run' do
    let(:temp_directory) { Dir.mktmpdir }
    let(:output_file_path) { temp_directory }
    let(:expected_file_path) { File.join(output_file_path, 'pg_settings.csv') }
    let(:output) { Gitlab::Database::Sos::Output.new(output_file_path, mode: :directory) }

    after do
      FileUtils.remove_entry(temp_directory)
    end

    it 'creates a CSV file with the correct headers and data' do
      described_class.run(output)
      output.finish

      expect(File.exist?(expected_file_path)).to be true

      csv_content = CSV.read(expected_file_path)

      expect(csv_content.first).to eq(%w[name setting description])

      block_size_row = csv_content.find { |row| row[0] == 'block_size' }

      expect(block_size_row).not_to be_nil
      # NOTE: 8192 bytes is the default value for the block size in Postgres so
      # it's safe to say this value will not change for us.
      expect(block_size_row[1]).to eq('8192')
    end
  end
end
