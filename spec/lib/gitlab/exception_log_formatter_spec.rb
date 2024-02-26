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
      expect(payload['exception.backtrace']).to eq(Rails.backtrace_cleaner.clean(backtrace))
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

    context 'when exception is a gRPC bad status' do
      let(:unavailable_error) do
        ::GRPC::Unavailable.new(
          "unavailable",
          gitaly_error_metadata: {
            storage: 'default',
            address: 'unix://gitaly.socket',
            service: :ref_service,
            rpc: :find_local_branches
          }
        )
      end

      context 'when the gRPC error is wrapped by ::Gitlab::Git::BaseError' do
        let(:exception) { ::Gitlab::Git::CommandError.new(unavailable_error) }

        it 'adds gitaly metadata to payload' do
          described_class.format!(exception, payload)

          expect(payload['exception.gitaly']).to eq('{:storage=>"default", :address=>"unix://gitaly.socket", :service=>:ref_service, :rpc=>:find_local_branches}')
        end
      end

      context 'when the gRPC error is wrapped by another error' do
        before do
          allow(exception).to receive(:cause).and_return(unavailable_error)
        end

        it 'adds gitaly metadata to payload' do
          described_class.format!(exception, payload)

          expect(payload['exception.cause_class']).to eq('GRPC::Unavailable')
          expect(payload['exception.gitaly']).to eq('{:storage=>"default", :address=>"unix://gitaly.socket", :service=>:ref_service, :rpc=>:find_local_branches}')
        end
      end

      context 'when the gRPC error is not wrapped' do
        let(:exception) { unavailable_error }

        it 'adds gitaly metadata to payload' do
          described_class.format!(exception, payload)

          expect(payload['exception.cause_class']).to be_nil
          expect(payload['exception.gitaly']).to eq('{:storage=>"default", :address=>"unix://gitaly.socket", :service=>:ref_service, :rpc=>:find_local_branches}')
        end
      end
    end
  end
end
