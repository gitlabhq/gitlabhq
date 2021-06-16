# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::Observers::QueryDetails do
  subject { described_class.new }

  let(:observation) { Gitlab::Database::Migrations::Observation.new(migration) }
  let(:connection) { ActiveRecord::Base.connection }
  let(:query) { "select date_trunc('day', $1::timestamptz) + $2 * (interval '1 hour')" }
  let(:query_binds) { [Time.current, 3] }
  let(:directory_path) { Dir.mktmpdir }
  let(:log_file) { "#{directory_path}/#{migration}-query-details.json" }
  let(:query_details) { Gitlab::Json.parse(File.read(log_file)) }
  let(:migration) { 20210422152437 }

  before do
    stub_const('Gitlab::Database::Migrations::Instrumentation::RESULT_DIR', directory_path)
  end

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
    subject.record(observation)
  end

  def run_query
    connection.exec_query(query, 'SQL', query_binds)
  end
end
