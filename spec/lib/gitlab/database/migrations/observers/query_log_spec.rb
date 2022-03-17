# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::Observers::QueryLog do
  subject { described_class.new(observation, directory_path, connection) }

  let(:observation) { Gitlab::Database::Migrations::Observation.new(version: migration_version, name: migration_name) }
  let(:connection) { ActiveRecord::Migration.connection }
  let(:query) { 'select 1' }
  let(:directory_path) { Dir.mktmpdir }
  let(:migration_version) { 20210422152437 }
  let(:migration_name) { 'test' }

  after do
    FileUtils.remove_entry(directory_path)
  end

  it 'writes a file with the query log' do
    observe

    expect(File.read("#{directory_path}/migration.log")).to include(query)
  end

  it 'does not change the default logger' do
    expect { observe }.not_to change { ActiveRecord::Base.logger }
  end

  def observe
    subject.before
    connection.execute(query)
    subject.after
    subject.record
  end
end
