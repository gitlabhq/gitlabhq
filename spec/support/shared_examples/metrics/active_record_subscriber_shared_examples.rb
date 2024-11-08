# frozen_string_literal: true

RSpec.shared_examples 'store ActiveRecord info in RequestStore' do |db_role, include_aggregated: false|
  let(:db_config_name) do
    db_config_name = ::Gitlab::Database.db_config_names(with_schema: :gitlab_shared).first
    db_config_name += "_replica" if db_role == :secondary
    db_config_name
  end

  let(:expected_payload_defaults) do
    result = {}
    metrics =
      ::Gitlab::Metrics::Subscribers::ActiveRecord.load_balancing_metric_counter_keys

    if include_aggregated
      metrics += ::Gitlab::Metrics::Subscribers::ActiveRecord.db_counter_keys +
        ::Gitlab::Metrics::Subscribers::ActiveRecord.load_balancing_roles_metric_counter_keys

      ::Gitlab::Metrics::Subscribers::ActiveRecord.load_balancing_roles_metric_duration_keys.each do |key|
        result[key] = 0.0
      end
    end

    metrics.each do |key|
      result[key] = 0
    end

    ::Gitlab::Metrics::Subscribers::ActiveRecord.load_balancing_metric_duration_keys.each do |key|
      result[key] = 0.0
    end

    result
  end

  def transform_hash(hash, another_hash)
    another_hash.each do |key, value|
      raise "Unexpected key: #{key}" unless hash[key]
    end

    hash.merge(another_hash)
  end

  it 'prevents db counters from leaking to the next transaction' do
    2.times do
      Gitlab::SafeRequestStore.ensure_request_store do
        subscriber.sql(event)

        case db_role
        when :primary
          subscriber_hash = {
            "db_#{db_config_name}_cached_count": record_cached_query ? 1 : 0,
            "db_#{db_config_name}_count": record_query ? 1 : 0,
            "db_#{db_config_name}_write_count": record_write_query ? 1 : 0,
            "db_#{db_config_name}_duration_s": record_query ? 0.002 : 0.0,
            "db_#{db_config_name}_wal_count": record_wal_query ? 1 : 0,
            "db_#{db_config_name}_wal_cached_count": record_wal_query && record_cached_query ? 1 : 0
          }

          if include_aggregated
            subscriber_hash = subscriber_hash.merge(
              db_count: record_query ? 1 : 0,
              db_write_count: record_write_query ? 1 : 0,
              db_cached_count: record_cached_query ? 1 : 0,
              db_primary_cached_count: record_cached_query ? 1 : 0,
              db_primary_count: record_query ? 1 : 0,
              db_primary_write_count: record_write_query ? 1 : 0,
              db_primary_duration_s: record_query ? 0.002 : 0.0,
              db_primary_wal_count: record_wal_query ? 1 : 0,
              db_primary_wal_cached_count: record_wal_query && record_cached_query ? 1 : 0
            )
          end
        when :replica
          subscriber_hash = {
            "db_#{db_config_name}_cached_count": record_cached_query ? 1 : 0,
            "db_#{db_config_name}_count": record_query ? 1 : 0,
            "db_#{db_config_name}_write_count": record_write_query ? 1 : 0,
            "db_#{db_config_name}_duration_s": record_query ? 0.002 : 0.0,
            "db_#{db_config_name}_wal_count": record_wal_query ? 1 : 0,
            "db_#{db_config_name}_wal_cached_count": record_wal_query && record_cached_query ? 1 : 0
          }

          if include_aggregated
            subscriber_hash = subscriber_hash.merge({
              db_count: record_query ? 1 : 0,
              db_write_count: record_write_query ? 1 : 0,
              db_cached_count: record_cached_query ? 1 : 0,
              db_replica_cached_count: record_cached_query ? 1 : 0,
              db_replica_count: record_query ? 1 : 0,
              db_replica_write_count: record_write_query ? 1 : 0,
              db_replica_duration_s: record_query ? 0.002 : 0.0,
              db_replica_wal_count: record_wal_query ? 1 : 0,
              db_replica_wal_cached_count: record_wal_query && record_cached_query ? 1 : 0
            })
          end
        else
          subscriber_hash = {
            "db_#{db_config_name}_cached_count": 0,
            "db_#{db_config_name}_count": 0,
            "db_#{db_config_name}_duration_s": 0.0,
            "db_#{db_config_name}_wal_count": 0,
            "db_#{db_config_name}_wal_cached_count": 0
          }

          if include_aggregated
            subscriber_hash = subscriber_hash.merge({
              db_count: record_query ? 1 : 0,
              db_write_count: record_write_query ? 1 : 0,
              db_cached_count: record_cached_query ? 1 : 0,
              db_primary_cached_count: 0,
              db_primary_count: 0,
              db_primary_duration_s: 0.0,
              db_primary_wal_count: 0,
              db_primary_wal_cached_count: 0
            })
          end
        end

        expected = transform_hash(expected_payload_defaults, subscriber_hash)

        expect(described_class.db_counter_payload).to eq(expected)
      end
    end
  end
end

RSpec.shared_examples 'record ActiveRecord metrics in a metrics transaction' do |db_role|
  let(:db_config_name) do
    db_config_name = ::Gitlab::Database.db_config_names(with_schema: :gitlab_shared).first
    db_config_name += "_replica" if db_role == :secondary
    db_config_name
  end

  it 'increments only db counters' do
    if record_query
      expect(transaction).to receive(:increment).with(:gitlab_transaction_db_count_total, 1, { db_config_name: db_config_name })
      expect(transaction).to receive(:increment).with("gitlab_transaction_db_#{db_role}_count_total".to_sym, 1, { db_config_name: db_config_name }) if db_role
    else
      expect(transaction).not_to receive(:increment).with(:gitlab_transaction_db_count_total, 1, { db_config_name: db_config_name })
      expect(transaction).not_to receive(:increment).with("gitlab_transaction_db_#{db_role}_count_total".to_sym, 1, { db_config_name: db_config_name }) if db_role
    end

    if record_write_query
      expect(transaction).to receive(:increment).with(:gitlab_transaction_db_write_count_total, 1, { db_config_name: db_config_name })
    else
      expect(transaction).not_to receive(:increment).with(:gitlab_transaction_db_write_count_total, 1, { db_config_name: db_config_name })
    end

    if record_cached_query
      expect(transaction).to receive(:increment).with(:gitlab_transaction_db_cached_count_total, 1, { db_config_name: db_config_name })
      expect(transaction).to receive(:increment).with("gitlab_transaction_db_#{db_role}_cached_count_total".to_sym, 1, { db_config_name: db_config_name }) if db_role
    else
      expect(transaction).not_to receive(:increment).with(:gitlab_transaction_db_cached_count_total, 1, { db_config_name: db_config_name })
      expect(transaction).not_to receive(:increment).with("gitlab_transaction_db_#{db_role}_cached_count_total".to_sym, 1, { db_config_name: db_config_name }) if db_role
    end

    if record_wal_query
      if db_role
        expect(transaction).to receive(:increment).with("gitlab_transaction_db_#{db_role}_wal_count_total".to_sym, 1, { db_config_name: db_config_name })
        expect(transaction).to receive(:increment).with("gitlab_transaction_db_#{db_role}_wal_cached_count_total".to_sym, 1, { db_config_name: db_config_name }) if record_cached_query
      end
    elsif db_role
      expect(transaction).not_to receive(:increment).with("gitlab_transaction_db_#{db_role}_wal_count_total".to_sym, 1, { db_config_name: db_config_name })
    end

    subscriber.sql(event)
  end

  it 'observes sql_duration metric' do
    if record_query
      expect(transaction).to receive(:observe).with(:gitlab_sql_duration_seconds, 0.002, { db_config_name: db_config_name })
      expect(transaction).to receive(:observe).with("gitlab_sql_#{db_role}_duration_seconds".to_sym, 0.002, { db_config_name: db_config_name }) if db_role
    else
      expect(transaction).not_to receive(:observe)
    end

    subscriber.sql(event)
  end
end

RSpec.shared_examples 'record ActiveRecord metrics' do |db_role|
  context 'when both web and background transaction are available' do
    let(:transaction) { double('Gitlab::Metrics::WebTransaction') }
    let(:background_transaction) { double('Gitlab::Metrics::WebTransaction') }

    before do
      allow(::Gitlab::Metrics::WebTransaction).to receive(:current)
        .and_return(transaction)
      allow(::Gitlab::Metrics::BackgroundTransaction).to receive(:current)
        .and_return(background_transaction)
      allow(transaction).to receive(:increment)
      allow(transaction).to receive(:observe)
    end

    it_behaves_like 'record ActiveRecord metrics in a metrics transaction', db_role

    it 'captures the metrics for web only' do
      expect(background_transaction).not_to receive(:observe)
      expect(background_transaction).not_to receive(:increment)

      subscriber.sql(event)
    end
  end

  context 'when web transaction is available' do
    let(:transaction) { double('Gitlab::Metrics::WebTransaction') }

    before do
      allow(::Gitlab::Metrics::WebTransaction).to receive(:current)
        .and_return(transaction)
      allow(::Gitlab::Metrics::BackgroundTransaction).to receive(:current)
        .and_return(nil)
      allow(transaction).to receive(:increment)
      allow(transaction).to receive(:observe)
    end

    it_behaves_like 'record ActiveRecord metrics in a metrics transaction', db_role
  end

  context 'when background transaction is available' do
    let(:transaction) { double('Gitlab::Metrics::BackgroundTransaction') }

    before do
      allow(::Gitlab::Metrics::WebTransaction).to receive(:current)
        .and_return(nil)
      allow(::Gitlab::Metrics::BackgroundTransaction).to receive(:current)
        .and_return(transaction)
      allow(transaction).to receive(:increment)
      allow(transaction).to receive(:observe)
    end

    it_behaves_like 'record ActiveRecord metrics in a metrics transaction', db_role
  end
end
