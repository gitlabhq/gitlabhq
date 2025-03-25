# frozen_string_literal: true

require 'spec_helper'
require 'generators/gitlab/click_house/migration_generator'
require 'fileutils'

if ::Gitlab.next_rails?
  require 'rails/generators/testing/behavior'
else
  require 'rails/generators/testing/behaviour'
end

RSpec.describe Gitlab::ClickHouse::MigrationGenerator, feature_category: :database do
  if ::Gitlab.next_rails?
    include Rails::Generators::Testing::Behavior
  else
    include Rails::Generators::Testing::Behaviour
  end

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
