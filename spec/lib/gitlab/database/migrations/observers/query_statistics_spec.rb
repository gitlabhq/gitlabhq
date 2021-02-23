# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::Observers::QueryStatistics do
  subject { described_class.new }

  let(:connection) { ActiveRecord::Base.connection }

  def mock_pgss(enabled: true)
    if enabled
      allow(subject).to receive(:function_exists?).with(:pg_stat_statements_reset).and_return(true)
      allow(connection).to receive(:view_exists?).with(:pg_stat_statements).and_return(true)
    else
      allow(subject).to receive(:function_exists?).with(:pg_stat_statements_reset).and_return(false)
      allow(connection).to receive(:view_exists?).with(:pg_stat_statements).and_return(false)
    end
  end

  describe '#before' do
    context 'with pgss available' do
      it 'resets pg_stat_statements' do
        mock_pgss(enabled: true)
        expect(connection).to receive(:execute).with('select pg_stat_statements_reset()').once

        subject.before
      end
    end

    context 'without pgss available' do
      it 'executes nothing' do
        mock_pgss(enabled: false)
        expect(connection).not_to receive(:execute)

        subject.before
      end
    end
  end

  describe '#record' do
    let(:observation) { Gitlab::Database::Migrations::Observation.new }
    let(:result) { double }
    let(:pgss_query) do
      <<~SQL
        SELECT query, calls, total_time, max_time, mean_time, rows
        FROM pg_stat_statements
        ORDER BY total_time DESC
      SQL
    end

    context 'with pgss available' do
      it 'fetches data from pg_stat_statements and stores on the observation' do
        mock_pgss(enabled: true)
        expect(connection).to receive(:execute).with(pgss_query).once.and_return(result)

        expect { subject.record(observation) }.to change { observation.query_statistics }.from(nil).to(result)
      end
    end

    context 'without pgss available' do
      it 'executes nothing' do
        mock_pgss(enabled: false)
        expect(connection).not_to receive(:execute)

        expect { subject.record(observation) }.not_to change { observation.query_statistics }
      end
    end
  end
end
