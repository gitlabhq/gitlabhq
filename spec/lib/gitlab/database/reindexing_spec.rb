# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Reindexing do
  include ExclusiveLeaseHelpers

  describe '.perform' do
    subject { described_class.perform(candidate_indexes) }

    let(:coordinator) { instance_double(Gitlab::Database::Reindexing::Coordinator) }
    let(:index_selection) { instance_double(Gitlab::Database::Reindexing::IndexSelection) }
    let(:candidate_indexes) { double }
    let(:indexes) { [double, double] }

    it 'delegates to Coordinator' do
      expect(Gitlab::Database::Reindexing::IndexSelection).to receive(:new).with(candidate_indexes).and_return(index_selection)
      expect(index_selection).to receive(:take).with(2).and_return(indexes)

      indexes.each do |index|
        expect(Gitlab::Database::Reindexing::Coordinator).to receive(:new).with(index).and_return(coordinator)
        expect(coordinator).to receive(:perform)
      end

      subject
    end
  end

  describe '.cleanup_leftovers!' do
    subject { described_class.cleanup_leftovers! }

    before do
      ApplicationRecord.connection.execute(<<~SQL)
        CREATE INDEX foobar_ccnew ON users (id);
        CREATE INDEX foobar_ccnew1 ON users (id);
      SQL
    end

    it 'drops both leftover indexes' do
      expect_query("SET lock_timeout TO '60000ms'")
      expect_query("DROP INDEX CONCURRENTLY IF EXISTS \"public\".\"foobar_ccnew\"")
      expect_query("RESET idle_in_transaction_session_timeout; RESET lock_timeout")
      expect_query("SET lock_timeout TO '60000ms'")
      expect_query("DROP INDEX CONCURRENTLY IF EXISTS \"public\".\"foobar_ccnew1\"")
      expect_query("RESET idle_in_transaction_session_timeout; RESET lock_timeout")

      subject
    end

    def expect_query(sql)
      expect(ApplicationRecord.connection).to receive(:execute).ordered.with(sql).and_wrap_original do |method, sql|
        method.call(sql.sub(/CONCURRENTLY/, ''))
      end
    end
  end
end
