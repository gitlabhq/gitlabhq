# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Transaction::Observer, feature_category: :database do
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
        User.first

        ActiveRecord::Base.transaction(requires_new: true) do
          User.first

          expect(transaction_context).to be_a(::Gitlab::Database::Transaction::Context)
          expect(context.keys).to match_array(%i[start_time depth savepoints queries backtraces external_http_count_start external_http_duration_start])
          expect(context[:depth]).to eq(2)
          expect(context[:savepoints]).to eq(1)
          expect(context[:queries].length).to eq(1)
        end
      end

      expect(context[:depth]).to eq(2)
      expect(context[:savepoints]).to eq(1)
      expect(context[:releases]).to eq(1)
      expect(context[:backtraces].length).to eq(1)
    end

    describe 'tracking external network requests', :request_store do
      it 'tracks external requests' do
        perform_stubbed_external_http_request(duration: 0.25)
        perform_stubbed_external_http_request(duration: 1.25)

        ActiveRecord::Base.transaction do
          User.first

          expect(context[:external_http_count_start]).to eq(2)
          expect(context[:external_http_duration_start]).to eq(1.5)

          perform_stubbed_external_http_request(duration: 1)
          perform_stubbed_external_http_request(duration: 3)

          expect(transaction_context.external_http_requests_count).to eq 2
          expect(transaction_context.external_http_requests_duration).to eq 4
        end
      end

      context 'when external HTTP requests duration has been exceeded' do
        it 'logs transaction details including exceeding thresholds' do
          expect(Gitlab::AppJsonLogger).to receive(:info).with(
            hash_including(
              external_http_requests_count: 2,
              external_http_requests_duration: 12
            )
          )

          ActiveRecord::Base.transaction do
            User.first

            perform_stubbed_external_http_request(duration: 2)
            perform_stubbed_external_http_request(duration: 10)
          end
        end
      end

      context 'when external HTTP requests count has been exceeded' do
        it 'logs transaction details including exceeding thresholds' do
          expect(Gitlab::AppJsonLogger).to receive(:info).with(
            hash_including(external_http_requests_count: 55)
          )

          ActiveRecord::Base.transaction do
            User.first

            55.times { perform_stubbed_external_http_request(duration: 0.01) }
          end
        end
      end

      def perform_stubbed_external_http_request(duration:)
        ::Gitlab::Metrics::Subscribers::ExternalHttp.new.request(
          instance_double(
            'ActiveSupport::Notifications::Event',
            payload: {
              method: 'GET', code: '200', duration: duration,
              scheme: 'http', host: 'example.gitlab.com', port: 80, path: '/'
            },
            time: Time.current
          )
        )
      end
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
