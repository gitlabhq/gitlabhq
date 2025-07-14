# frozen_string_literal: true

RSpec.shared_examples_for 'ClickHouse migration generator' do
  # These shared examples require migration_path variable to be defined
  include Rails::Generators::Testing::Behavior
  include FileUtils

  let(:migration_name) { "CreateProjects" }
  let(:migration_file) do
    Dir.glob(File.join(destination_root, "#{migration_path}/main/*_create_projects.rb")).first
  end

  destination Dir.mktmpdir

  before do
    prepare_destination
    generator = described_class.new([migration_name], {}, {})
    generator.destination_root = destination_root

    generator.invoke_all
  end

  after do
    FileUtils.rm_rf(destination_root)
  end

  it "creates the correct migration file" do
    expect(File).to exist(migration_file)
  end

  it "uses the correct migration template" do
    expect(File.read(migration_file)).to include("class CreateProjects < ClickHouse::Migration")
  end
end
