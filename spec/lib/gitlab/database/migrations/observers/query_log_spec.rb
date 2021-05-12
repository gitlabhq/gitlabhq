# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::Observers::QueryLog do
  subject { described_class.new }

  let(:observation) { Gitlab::Database::Migrations::Observation.new(migration) }
  let(:connection) { ActiveRecord::Base.connection }
  let(:query) { 'select 1' }
  let(:directory_path) { Dir.mktmpdir }
  let(:log_file) { "#{directory_path}/current.log" }
  let(:migration) { 20210422152437 }

  before do
    stub_const('Gitlab::Database::Migrations::Instrumentation::RESULT_DIR', directory_path)
  end

  after do
    FileUtils.remove_entry(directory_path)
  end

  it 'writes a file with the query log' do
    observe

    expect(File.read("#{directory_path}/#{migration}.log")).to include(query)
  end

  it 'does not change the default logger' do
    expect { observe }.not_to change { ActiveRecord::Base.logger }
  end

  def observe
    subject.before
    connection.execute(query)
    subject.after
    subject.record(observation)
  end
end
