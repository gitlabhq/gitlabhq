# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PostgresAutovacuumActivity, type: :model, feature_category: :database do
  include Database::DatabaseHelpers

  it { is_expected.to be_a Gitlab::Database::SharedModel }

  describe '.for_tables' do
    subject { described_class.for_tables(tables) }

    let(:tables) { %w[foo test] }

    before do
      swapout_view_for_table(:postgres_autovacuum_activity, connection: ApplicationRecord.connection)

      # unrelated
      create(:postgres_autovacuum_activity, table: 'bar')

      tables.each do |table|
        create(:postgres_autovacuum_activity, table: table)
      end

      expect(Gitlab::Database::LoadBalancing::SessionMap.current(ApplicationRecord.load_balancer))
        .to receive(:use_primary).and_yield
    end

    it 'returns autovacuum activity for queries tables' do
      expect(subject.map(&:table).sort).to eq(tables)
    end

    it 'executes the query' do
      is_expected.to be_a Array
    end
  end

  describe '.wraparound_prevention' do
    subject { described_class.wraparound_prevention }

    it { expect(subject.where_values_hash).to match(a_hash_including('wraparound_prevention' => true)) }
  end
end
