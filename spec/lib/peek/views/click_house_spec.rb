# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Peek::Views::ClickHouse, :click_house, :request_store, feature_category: :database do
  before do
    allow(::Gitlab::PerformanceBar).to receive(:enabled_for_request?).and_return(true)
  end

  describe '#results' do
    let(:results) { described_class.new.results }

    it 'includes performance details' do
      ::Gitlab::SafeRequestStore.clear!

      data = ClickHouse::Client.select('SELECT 1 AS value', :main)
      ClickHouse::Client.execute('INSERT INTO events (id) VALUES (1)', :main)

      Tempfile.open(['test', '.csv.gz']) do |f|
        File.binwrite(f.path, ActiveSupport::Gzip.compress("id\n10\n20"))

        ClickHouse::Client.insert_csv('INSERT INTO events (id) FORMAT CSV', File.open(f.path), :main)
      end

      expect(data).to eq([{ 'value' => 1 }])

      expect(results[:calls]).to eq(3)
      expect(results[:duration]).to be_kind_of(String)

      expect(results[:details]).to match_array([
        a_hash_including({
          sql: 'SELECT 1 AS value',
          database: 'database: main'
        }),
        a_hash_including({
          sql: 'INSERT INTO events (id) VALUES (1)',
          database: 'database: main'
        }),
        a_hash_including({
          sql: 'INSERT INTO events (id) FORMAT CSV',
          database: 'database: main'
        })
      ])
    end
  end
end
