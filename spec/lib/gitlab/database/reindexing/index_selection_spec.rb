# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Reindexing::IndexSelection, feature_category: :database do
  include Database::DatabaseHelpers

  subject { described_class.new(Gitlab::Database::PostgresIndex.all).to_a }

  let(:connection) { ApplicationRecord.connection }

  before do
    swapout_view_for_table(:postgres_index_bloat_estimates, connection: connection)
    swapout_view_for_table(:postgres_indexes, connection: connection)

    create_list(:postgres_index, 10, ondisk_size_bytes: 10.gigabytes).each_with_index do |index, i|
      create(:postgres_index_bloat_estimate, index: index, bloat_size_bytes: 2.gigabyte * (i + 1))
    end
  end

  def execute(sql)
    connection.execute(sql)
  end

  it 'orders by highest relative bloat first' do
    expected = Gitlab::Database::PostgresIndex.all.sort_by(&:relative_bloat_level).reverse.map(&:name)

    expect(subject.map(&:name)).to eq(expected)
  end

  it 'excludes indexes with a relative bloat level below 20%' do
    excluded = create(
      :postgres_index_bloat_estimate,
      index: create(:postgres_index, ondisk_size_bytes: 10.gigabytes),
      bloat_size_bytes: 1.9.gigabyte # 19% relative index bloat
    )

    expect(subject).not_to include(excluded.index)
  end

  it 'excludes indexes smaller than 1 GiB ondisk size' do
    excluded = create(
      :postgres_index_bloat_estimate,
      index: create(:postgres_index, ondisk_size_bytes: 0.99.gigabytes),
      bloat_size_bytes: 0.8.gigabyte
    )

    expect(subject).not_to include(excluded.index)
  end

  it 'includes indexes larger than 100 GiB ondisk size' do
    included = create(
      :postgres_index_bloat_estimate,
      index: create(:postgres_index, ondisk_size_bytes: 101.gigabytes),
      bloat_size_bytes: 25.gigabyte
    )

    expect(subject).to include(included.index)
  end

  context 'with time frozen' do
    around do |example|
      freeze_time { example.run }
    end

    it 'does not return indexes with reindex action in the last 10 days' do
      not_recently_reindexed = Gitlab::Database::PostgresIndex.all.each do |index|
        create(:reindex_action, index: index, action_end: Time.zone.now - 10.days - 1.minute)
      end

      create_list(:postgres_index, 10, ondisk_size_bytes: 10.gigabytes).each_with_index do |index, i|
        create(:postgres_index_bloat_estimate, index: index, bloat_size_bytes: 2.gigabyte * (i + 1))
        create(:reindex_action, index: index, action_end: Time.zone.now)
      end

      expect(subject.map(&:name).sort).to eq(not_recently_reindexed.map(&:name).sort)
    end
  end

  context 'with restricted tables' do
    let!(:ci_builds) do
      create(
        :postgres_index_bloat_estimate,
        index: create(:postgres_index, ondisk_size_bytes: 100.gigabytes, tablename: 'ci_builds'),
        bloat_size_bytes: 20.gigabyte
      )
    end

    context 'when executed on Fridays', time_travel_to: '2022-12-16T09:44:07Z' do
      it { expect(subject).not_to include(ci_builds.index) }
    end

    context 'when executed on Saturdays', time_travel_to: '2022-12-17T09:44:07Z' do
      it { expect(subject).to include(ci_builds.index) }
    end

    context 'when executed on Sundays', time_travel_to: '2022-12-18T09:44:07Z' do
      it { expect(subject).not_to include(ci_builds.index) }
    end

    context 'when executed on Mondays', time_travel_to: '2022-12-19T09:44:07Z' do
      it { expect(subject).not_to include(ci_builds.index) }
    end
  end
end
