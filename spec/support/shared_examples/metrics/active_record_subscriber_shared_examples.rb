# frozen_string_literal: true

RSpec.shared_examples 'store ActiveRecord info in RequestStore' do |db_role|
  it 'prevents db counters from leaking to the next transaction' do
    2.times do
      Gitlab::WithRequestStore.with_request_store do
        subscriber.sql(event)

        if db_role == :primary
          expect(described_class.db_counter_payload).to eq(
            db_count: record_query ? 1 : 0,
            db_write_count: record_write_query ? 1 : 0,
            db_cached_count: record_cached_query ? 1 : 0,
            db_primary_cached_count:  record_cached_query ? 1 : 0,
            db_primary_count:  record_query ? 1 : 0,
            db_primary_duration_s:  record_query ? 0.002 : 0,
            db_replica_cached_count:  0,
            db_replica_count:  0,
            db_replica_duration_s:  0.0
          )
        elsif db_role == :replica
          expect(described_class.db_counter_payload).to eq(
            db_count: record_query ? 1 : 0,
            db_write_count: record_write_query ? 1 : 0,
            db_cached_count: record_cached_query ? 1 : 0,
            db_primary_cached_count:  0,
            db_primary_count:  0,
            db_primary_duration_s:  0.0,
            db_replica_cached_count:  record_cached_query ? 1 : 0,
            db_replica_count:  record_query ? 1 : 0,
            db_replica_duration_s:  record_query ? 0.002 : 0
          )
        else
          expect(described_class.db_counter_payload).to eq(
            db_count: record_query ? 1 : 0,
            db_write_count: record_write_query ? 1 : 0,
            db_cached_count: record_cached_query ? 1 : 0
          )
        end
      end
    end
  end
end

RSpec.shared_examples 'record ActiveRecord metrics' do |db_role|
  it 'increments only db counters' do
    if record_query
      expect(transaction).to receive(:increment).with(:gitlab_transaction_db_count_total, 1)
      expect(transaction).to receive(:increment).with("gitlab_transaction_db_#{db_role}_count_total".to_sym, 1) if db_role
    else
      expect(transaction).not_to receive(:increment).with(:gitlab_transaction_db_count_total, 1)
      expect(transaction).not_to receive(:increment).with("gitlab_transaction_db_#{db_role}_count_total".to_sym, 1) if db_role
    end

    if record_write_query
      expect(transaction).to receive(:increment).with(:gitlab_transaction_db_write_count_total, 1)
    else
      expect(transaction).not_to receive(:increment).with(:gitlab_transaction_db_write_count_total, 1)
    end

    if record_cached_query
      expect(transaction).to receive(:increment).with(:gitlab_transaction_db_cached_count_total, 1)
      expect(transaction).to receive(:increment).with("gitlab_transaction_db_#{db_role}_cached_count_total".to_sym, 1) if db_role
    else
      expect(transaction).not_to receive(:increment).with(:gitlab_transaction_db_cached_count_total, 1)
      expect(transaction).not_to receive(:increment).with("gitlab_transaction_db_#{db_role}_cached_count_total".to_sym, 1) if db_role
    end

    subscriber.sql(event)
  end

  it 'observes sql_duration metric' do
    if record_query
      expect(transaction).to receive(:observe).with(:gitlab_sql_duration_seconds, 0.002)
      expect(transaction).to receive(:observe).with("gitlab_sql_#{db_role}_duration_seconds".to_sym, 0.002) if db_role
    else
      expect(transaction).not_to receive(:observe)
    end

    subscriber.sql(event)
  end
end
