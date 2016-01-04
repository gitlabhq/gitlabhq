require 'spec_helper'

describe Gitlab::Metrics::Subscribers::ActiveRecord do
  let(:transaction) { Gitlab::Metrics::Transaction.new }
  let(:subscriber)  { described_class.new }

  let(:event) do
    double(:event, duration: 0.2,
                   payload:  { sql: 'SELECT * FROM users WHERE id = 10' })
  end

  describe '#sql' do
    describe 'without a current transaction' do
      it 'simply returns' do
        expect_any_instance_of(Gitlab::Metrics::Transaction).
          to_not receive(:increment)

        subscriber.sql(event)
      end
    end

    describe 'with a current transaction' do
      it 'increments the :sql_duration value' do
        expect(subscriber).to receive(:current_transaction).
          at_least(:once).
          and_return(transaction)

        expect(transaction).to receive(:increment).
          with(:sql_duration, 0.2)

        subscriber.sql(event)
      end
    end
  end
end
