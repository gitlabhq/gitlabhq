# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Patch::ConnectionPoolExtendedStat, feature_category: :database do
  # Use a dedicated connection pool to
  # - avoid rails transactional test connection pinning behavior
  # - avoid racing with the dead connection reaper configured for the normal connection pool
  let(:pool_config) do
    orig_pool_config = ApplicationRecord.connection_pool.pool_config
    orig_db_config = orig_pool_config.db_config
    db_config = ActiveRecord::DatabaseConfigurations::HashConfig.new(
      orig_db_config.env_name,
      orig_db_config.name,
      # disable the dead connection reaper so it doesn't race with the test
      orig_db_config.configuration_hash.merge(reaping_frequency: 0)
    )
    ActiveRecord::ConnectionAdapters::PoolConfig.new(
      orig_db_config.adapter_class,
      db_config,
      orig_pool_config.role,
      orig_pool_config.shard
    )
  end

  let(:pool) do
    pool_config.pool
  end

  after do
    pool_config.disconnect!
  end

  it 'includes the module' do
    expect(ActiveRecord::ConnectionAdapters::ConnectionPool < described_class).to be_truthy
  end

  it 'counts busy threads by name' do
    checked_out_latch = Concurrent::CountDownLatch.new(1)
    thread_end_latch = Concurrent::CountDownLatch.new(1)

    thread = Thread.new do
      Rails.application.executor.wrap do
        Thread.current.name = "test_thread"
        expect(pool.active_connection?).to be_falsey

        pool.lease_connection

        checked_out_latch.count_down
        thread_end_latch.wait
      end
    end

    checked_out_latch.wait

    expect(pool.extended_stat[:busy_by_thread_name]['test_thread']).to eq(1)

    thread_end_latch.count_down
    thread.join

    expect(pool.extended_stat[:busy_by_thread_name]).not_to include('test_thread')
  end

  it 'counts dead threads by name' do
    thread = Thread.new do
      Thread.current.name = "test_thread"
      pool.lease_connection # Without wrapping in an executor
    end

    thread.join

    expect(pool.extended_stat[:dead_by_thread_name]).to eq({ "test_thread" => 1 })
  end

  it 'provides stat output consistent with ConnectionPool#stat' do
    extended_stat = ApplicationRecord.connection_pool.extended_stat

    basic_stat = ApplicationRecord.connection_pool.stat

    extended_stat_total_busy = extended_stat[:busy_by_thread_name].values.sum
    extended_stat_total_dead = extended_stat[:dead_by_thread_name].values.sum

    expected_basic_stat = extended_stat
                            .except(:busy_by_thread_name, :dead_by_thread_name)
                            .merge(busy: extended_stat_total_busy, dead: extended_stat_total_dead)

    expect(expected_basic_stat).to eq(basic_stat)
  end
end
