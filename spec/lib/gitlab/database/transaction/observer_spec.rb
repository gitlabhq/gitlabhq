# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Transaction::Observer do
  # Use the delete DB strategy so that the test won't be wrapped in a transaction
  describe '.instrument_transactions', :delete do
    let(:transaction_context) { ActiveRecord::Base.connection.transaction_manager.transaction_context }
    let(:context) { transaction_context.context }

    around do |example|
      # Emulate production environment when SQL comments come first to avoid truncation
      Marginalia::Comment.prepend_comment = true
      subscriber = described_class.register!

      example.run

      ActiveSupport::Notifications.unsubscribe(subscriber)
      Marginalia::Comment.prepend_comment = false
    end

    it 'tracks transaction data', :aggregate_failures do
      ActiveRecord::Base.transaction do
        ActiveRecord::Base.transaction(requires_new: true) do
          User.first

          expect(transaction_context).to be_a(::Gitlab::Database::Transaction::Context)
          expect(context.keys).to match_array(%i(start_time depth savepoints queries))
          expect(context[:depth]).to eq(2)
          expect(context[:savepoints]).to eq(1)
          expect(context[:queries].length).to eq(1)
        end
      end

      expect(context[:depth]).to eq(2)
      expect(context[:savepoints]).to eq(1)
      expect(context[:releases]).to eq(1)
    end

    describe '.extract_sql_command' do
      using RSpec::Parameterized::TableSyntax

      where(:sql, :expected) do
        'SELECT 1' | 'SELECT 1'
        '/* test comment */ SELECT 1' | 'SELECT 1'
        '/* test comment */ ROLLBACK TO SAVEPOINT point1' | 'ROLLBACK TO SAVEPOINT '
        'SELECT 1 /* trailing comment */' | 'SELECT 1 /* trailing comment */'
      end

      with_them do
        it do
          expect(described_class.extract_sql_command(sql)).to eq(expected)
        end
      end
    end
  end
end
