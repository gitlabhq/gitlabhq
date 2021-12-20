# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::Observers::TotalDatabaseSizeChange do
  subject { described_class.new(observation, double('unused path'), connection) }

  let(:observation) { Gitlab::Database::Migrations::Observation.new }
  let(:connection) { ActiveRecord::Migration.connection }
  let(:query) { 'select pg_database_size(current_database())' }

  it 'records the size change' do
    expect(connection).to receive(:execute).with(query).once.and_return([{ 'pg_database_size' => 1024 }])
    expect(connection).to receive(:execute).with(query).once.and_return([{ 'pg_database_size' => 256 }])

    subject.before
    subject.after
    subject.record

    expect(observation.total_database_size_change).to eq(256 - 1024)
  end

  context 'out of order calls' do
    before do
      allow(connection).to receive(:execute).with(query).and_return([{ 'pg_database_size' => 1024 }])
    end

    it 'does not record anything if before size is unknown' do
      subject.after

      expect { subject.record }.not_to change { observation.total_database_size_change }
    end

    it 'does not record anything if after size is unknown' do
      subject.before

      expect { subject.record }.not_to change { observation.total_database_size_change }
    end
  end
end
