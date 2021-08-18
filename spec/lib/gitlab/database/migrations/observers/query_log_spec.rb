# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::Observers::QueryLog do
  subject { described_class.new(observation) }

  let(:observation) { Gitlab::Database::Migrations::Observation.new(migration_version, migration_name) }
  let(:connection) { ActiveRecord::Base.connection }
  let(:query) { 'select 1' }
  let(:directory_path) { Dir.mktmpdir }
  let(:migration_version) { 20210422152437 }
  let(:migration_name) { 'test' }

  before do
    stub_const('Gitlab::Database::Migrations::Instrumentation::RESULT_DIR', directory_path)
  end

  after do
    FileUtils.remove_entry(directory_path)
  end

  it 'writes a file with the query log' do
    observe

    expect(File.read("#{directory_path}/#{migration_version}_#{migration_name}.log")).to include(query)
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
