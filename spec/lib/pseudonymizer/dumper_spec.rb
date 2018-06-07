require 'spec_helper'

describe Pseudonymizer::Dumper do
  let!(:project) { create(:project) }
  let(:base_dir) { Dir.mktmpdir }
  let(:options) { Pseudonymizer::Options.new() }
  subject(:pseudo) { described_class.new(options) }

  after do
    FileUtils.rm_rf(base_dir)
  end

  # create temp directory in before block
  describe 'Pseudo tables' do
    it 'outputs project tables to csv' do
      pseudo.config["output"]["csv"] = base_dir
      pseudo.config["tables"] = {
        "projects" => {
          "whitelist" => %w(id name path description),
          "pseudo" => %w(id)
        }
      }

      expect(pseudo.config["output"]["csv"]).to eq(base_dir)

      # grab the first table it outputs. There would only be 1.
      project_table_file = pseudo.tables_to_csv[0]
      # Ignore the `.` and `..` in the directory.

      expect(project_table_file.include? "projects_").to be true
      expect(project_table_file.include? ".csv").to be true
      columns = []
      project_data = []
      File.foreach(project_table_file).with_index do |line, line_num|
        if line_num == 0
          columns = line.split(",")
        end

        if line_num == 1
          project_data = line.split(",")
          break
        end
      end
      # check if CSV columns are correct
      expect(columns.to_set).to eq(%W(id name path description\n).to_set)

      # is it pseudonymous
      expect(project_data[0]).not_to eq(1)
      # sha 256 is 64 chars in length
      expect(project_data[0].length).to eq(64)
    end
  end
end
