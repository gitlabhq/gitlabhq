# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Reindexing::IndexSelection do
  include Database::DatabaseHelpers

  subject { described_class.new(Gitlab::Database::PostgresIndex.all).to_a }

  before do
    swapout_view_for_table(:postgres_index_bloat_estimates)
    swapout_view_for_table(:postgres_indexes)
  end

  def execute(sql)
    ActiveRecord::Base.connection.execute(sql)
  end

  it 'orders by highest bloat first' do
    create_list(:postgres_index, 10).each_with_index do |index, i|
      create(:postgres_index_bloat_estimate, index: index, bloat_size_bytes: 1.megabyte * i)
    end

    expected = Gitlab::Database::PostgresIndexBloatEstimate.order(bloat_size_bytes: :desc).map(&:index)

    expect(subject).to eq(expected)
  end

  context 'with time frozen' do
    around do |example|
      freeze_time { example.run }
    end

    it 'does not return indexes with reindex action in the last 7 days' do
      not_recently_reindexed = create_list(:postgres_index, 2).each_with_index do |index, i|
        create(:postgres_index_bloat_estimate, index: index, bloat_size_bytes: 1.megabyte * i)
        create(:reindex_action, index: index, action_end: Time.zone.now - 7.days - 1.minute)
      end

      create_list(:postgres_index, 2).each_with_index do |index, i|
        create(:postgres_index_bloat_estimate, index: index, bloat_size_bytes: 1.megabyte * i)
        create(:reindex_action, index: index, action_end: Time.zone.now)
      end

      expected = Gitlab::Database::PostgresIndexBloatEstimate.where(identifier: not_recently_reindexed.map(&:identifier)).map(&:index).map(&:identifier).sort

      expect(subject.map(&:identifier).sort).to eq(expected)
    end
  end
end
