require 'spec_helper'

describe Pseudonymizer::Dumper do
  let!(:project) { create(:project) }
  let(:base_dir) { Dir.mktmpdir }
  let(:options) do
    Pseudonymizer::Options.new(
      config: YAML.load_file(Gitlab.config.pseudonymizer.manifest)
    )
  end
  subject(:pseudo) { described_class.new(options) }

  before do
    allow(options).to receive(:output_dir).and_return(base_dir)
  end

  after do
    FileUtils.rm_rf(base_dir)
  end

  describe 'Pseudo tables' do
    it 'outputs project tables to csv' do
      column_names = %w(id name path description)
      pseudo.config[:tables] = {
        projects: {
          whitelist: column_names,
          pseudo: %w(id)
        }
      }

      expect(pseudo.output_dir).to eq(base_dir)

      # grab the first table it outputs. There would only be 1.
      project_table_file = pseudo.tables_to_csv[0]
      expect(project_table_file).to include("projects.csv.gz")

      columns = []
      project_data = []
      Zlib::GzipReader.open(project_table_file) do |gz|
        csv = CSV.new(gz, headers: true)
        # csv.shift # read the header row
        project_data = csv.gets
        columns = csv.headers
      end

      # check if CSV columns are correct
      expect(columns).to include(*column_names)

      # is it pseudonymous
      # sha 256 is 64 chars in length
      expect(project_data["id"].length).to eq(64)
    end
  end

  describe "manifest is valid" do
    it "all tables exist" do
      existing_tables = ActiveRecord::Base.connection.tables
      tables = options.config['tables'].keys

      expect(existing_tables).to include(*tables)
    end

    it "all whitelisted attributes exist" do
      options.config['tables'].each do |table, table_def|
        whitelisted = table_def['whitelist']
        existing_columns = ActiveRecord::Base.connection.columns(table.to_sym).map(&:name)
        diff = whitelisted - existing_columns

        expect(diff).to be_empty, "#{table} should define columns #{whitelisted.inspect}: missing #{diff.inspect}"
      end
    end

    it "all pseudonymized attributes are whitelisted" do
      options.config['tables'].each do |table, table_def|
        whitelisted = table_def['whitelist']
        pseudonymized = table_def['pseudo']
        diff = pseudonymized - whitelisted

        expect(diff).to be_empty, "#{table} should whitelist columns #{pseudonymized.inspect}: missing #{diff.inspect}"
      end
    end
  end
end
