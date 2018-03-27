require 'spec_helper'

describe Gitlab::Metrics::Subscribers::ActiveRecord do
  let(:env) { {} }
  let(:transaction) { Gitlab::Metrics::WebTransaction.new(env) }
  let(:subscriber)  { described_class.new }

  let(:event) do
    double(:event, duration: 2,
                   payload:  { sql: 'SELECT * FROM users WHERE id = 10' })
  end

  describe '#sql' do
    describe 'without a current transaction' do
      it 'simply returns' do
        expect_any_instance_of(Gitlab::Metrics::Transaction)
          .not_to receive(:increment)

        subscriber.sql(event)
      end
    end

    describe 'with a current transaction' do
      it 'observes sql_duration metric' do
        expect(subscriber).to receive(:current_transaction)
                                .at_least(:once)
                                .and_return(transaction)
        expect(described_class.send(:gitlab_sql_duration_seconds)).to receive(:observe).with({}, 0.002)
        subscriber.sql(event)
      end

      it 'increments the :sql_duration value' do
        expect(subscriber).to receive(:current_transaction)
          .at_least(:once)
          .and_return(transaction)

        expect(transaction).to receive(:increment)
          .with(:sql_duration, 2, false)

        expect(transaction).to receive(:increment)
          .with(:sql_count, 1, false)

        subscriber.sql(event)
      end
    end
  end
end
