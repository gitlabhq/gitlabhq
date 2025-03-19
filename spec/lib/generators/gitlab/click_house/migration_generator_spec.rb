# frozen_string_literal: true

require 'spec_helper'
require 'rails/generators/testing/behaviour'
require 'generators/gitlab/click_house/migration_generator'
require 'fileutils'

RSpec.describe Gitlab::ClickHouse::MigrationGenerator, feature_category: :database do
  include Rails::Generators::Testing::Behaviour
  include FileUtils

  let(:migration_name) { "CreateProjects" }
  let(:migration_file) do
    Dir.glob(File.join(destination_root, "db/click_house/migrate/main/*_create_projects.rb")).first
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
