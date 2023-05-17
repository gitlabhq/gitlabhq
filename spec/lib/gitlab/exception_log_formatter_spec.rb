# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ExceptionLogFormatter do
  describe '.format!' do
    let(:exception) { RuntimeError.new('bad request') }
    let(:backtrace) { caller }

    let(:payload) { {} }

    before do
      allow(exception).to receive(:backtrace).and_return(backtrace)
    end

    it 'adds exception data to log' do
      described_class.format!(exception, payload)

      expect(payload['exception.class']).to eq('RuntimeError')
      expect(payload['exception.message']).to eq('bad request')
      expect(payload['exception.backtrace']).to eq(Gitlab::BacktraceCleaner.clean_backtrace(backtrace))
      expect(payload['exception.sql']).to be_nil
    end

    it 'cleans the exception message' do
      expect(Gitlab::Sanitizers::ExceptionMessage).to receive(:clean).with('RuntimeError', 'bad request').and_return('cleaned')

      described_class.format!(exception, payload)

      expect(payload['exception.message']).to eq('cleaned')
    end

    context 'when exception is ActiveRecord::StatementInvalid' do
      let(:exception) { ActiveRecord::StatementInvalid.new(sql: 'SELECT "users".* FROM "users" WHERE "users"."id" = 1 AND "users"."foo" = $1') }

      it 'adds the normalized SQL query to payload' do
        described_class.format!(exception, payload)

        expect(payload['exception.sql']).to eq('SELECT "users".* FROM "users" WHERE "users"."id" = $2 AND "users"."foo" = $1')
      end
    end

    context 'when the ActiveRecord::StatementInvalid is wrapped in another exception' do
      before do
        allow(exception).to receive(:cause).and_return(ActiveRecord::StatementInvalid.new(sql: 'SELECT "users".* FROM "users" WHERE "users"."id" = 1 AND "users"."foo" = $1'))
      end

      it 'adds the cause_class to payload' do
        described_class.format!(exception, payload)

        expect(payload['exception.cause_class']).to eq('ActiveRecord::StatementInvalid')
      end

      it 'adds the normalized SQL query to payload' do
        described_class.format!(exception, payload)

        expect(payload['exception.sql']).to eq('SELECT "users".* FROM "users" WHERE "users"."id" = $2 AND "users"."foo" = $1')
      end
    end

    context 'when the ActiveRecord::StatementInvalid is a bad query' do
      let(:exception) { ActiveRecord::StatementInvalid.new(sql: 'SELECT SELECT FROM SELECT') }

      it 'adds the query as-is to payload' do
        described_class.format!(exception, payload)

        expect(payload['exception.sql']).to eq('SELECT SELECT FROM SELECT')
      end
    end
  end
end
