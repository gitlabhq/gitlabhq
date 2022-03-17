# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::Observers::QueryDetails do
  subject { described_class.new(observation, directory_path, connection) }

  let(:connection) { ActiveRecord::Migration.connection }
  let(:observation) { Gitlab::Database::Migrations::Observation.new(version: migration_version, name: migration_name) }
  let(:query) { "select date_trunc('day', $1::timestamptz) + $2 * (interval '1 hour')" }
  let(:query_binds) { [Time.current, 3] }
  let(:directory_path) { Dir.mktmpdir }
  let(:log_file) { "#{directory_path}/query-details.json" }
  let(:query_details) { Gitlab::Json.parse(File.read(log_file)) }
  let(:migration_version) { 20210422152437 }
  let(:migration_name) { 'test' }

  after do
    FileUtils.remove_entry(directory_path)
  end

  it 'records details of executed queries' do
    observe

    expect(query_details.size).to eq(1)

    log_entry = query_details[0]
    start_time, end_time, sql, binds = log_entry.values_at('start_time', 'end_time', 'sql', 'binds')
    start_time = DateTime.parse(start_time)
    end_time = DateTime.parse(end_time)

    aggregate_failures do
      expect(sql).to include(query)
      expect(start_time).to be_before(end_time)
      expect(binds).to eq(query_binds.map { |b| connection.type_cast(b) })
    end
  end

  it 'unsubscribes after the observation' do
    observe

    expect(subject).not_to receive(:record_sql_event)
    run_query
  end

  def observe
    subject.before
    run_query
    subject.after
    subject.record
  end

  def run_query
    connection.exec_query(query, 'SQL', query_binds)
  end
end
