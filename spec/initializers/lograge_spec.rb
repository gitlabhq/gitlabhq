# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'lograge', type: :request, feature_category: :observability do
  let(:headers) { { 'X-Request-ID' => 'new-correlation-id' } }

  let(:large_params) do
    half_limit = Gitlab::Utils::LogLimitedArray::MAXIMUM_ARRAY_LENGTH / 2

    {
      a: 'a',
      b: 'b' * half_limit,
      c: 'c' * half_limit,
      d: 'd'
    }
  end

  let(:limited_params) do
    large_params.slice(:a, :b).map { |k, v| { key: k.to_s, value: v } } + [{ key: 'truncated', value: '...' }]
  end

  context 'for API requests' do
    it 'logs to api_json log' do
      # we assert receiving parameters by grape logger
      expect_any_instance_of(Gitlab::GrapeLogging::Formatters::LogrageWithTimestamp).to receive(:call)
        .with(anything, anything, anything, a_hash_including("correlation_id" => "new-correlation-id"))
        .and_call_original

      get("/api/v4/endpoint", params: {}, headers: headers)
    end

    it 'limits param size' do
      expect(Lograge.formatter).to receive(:call)
        .with(a_hash_including(params: limited_params))
        .and_call_original

      get("/api/v4/endpoint", params: large_params, headers: headers)
    end
  end

  context 'for Controller requests' do
    subject { get("/", params: {}, headers: headers) }

    it 'logs to production_json log' do
      # formatter receives a hash with correlation id
      expect(Lograge.formatter).to receive(:call)
        .with(a_hash_including("correlation_id" => "new-correlation-id"))
        .and_call_original

      # a log file receives a line with correlation id
      expect(Lograge.logger).to receive(:send)
        .with(anything, include('"correlation_id":"new-correlation-id"'))
        .and_call_original

      subject
    end

    it 'logs cpu_s on supported platform' do
      allow(Gitlab::Metrics::System).to receive(:thread_cpu_time)
        .and_return(
          0.111222333,
          0.222333833
        )

      expect(Lograge.formatter).to receive(:call)
        .with(a_hash_including(cpu_s: 0.111112))
        .and_call_original

      expect(Lograge.logger).to receive(:send)
        .with(anything, include('"cpu_s":0.111112'))
        .and_call_original

      subject
    end

    it 'does not log cpu_s on unsupported platform' do
      allow(Gitlab::Metrics::System).to receive(:thread_cpu_time)
        .and_return(nil)

      expect(Lograge.formatter).to receive(:call)
        .with(hash_not_including(:cpu_s))
        .and_call_original

      expect(Lograge.logger).not_to receive(:send)
        .with(anything, include('"cpu_s":'))
        .and_call_original

      subject
    end

    context 'when logging memory allocations' do
      include MemoryInstrumentationHelper

      before do
        verify_memory_instrumentation_available!
      end

      it 'logs memory usage metrics' do
        expect(Lograge.formatter).to receive(:call)
          .with(a_hash_including(:mem_objects))
          .and_call_original

        expect(Lograge.logger).to receive(:send)
          .with(anything, include('"mem_objects":'))
          .and_call_original

        subject
      end
    end

    it 'limits param size' do
      expect(Lograge.formatter).to receive(:call)
        .with(a_hash_including(params: limited_params))
        .and_call_original

      get("/", params: large_params, headers: headers)
    end
  end

  context 'with a log subscriber' do
    include_context 'parsed logs'

    let(:subscriber) { Lograge::LogSubscribers::ActionController.new }

    let(:event) do
      ActiveSupport::Notifications::Event.new(
        'process_action.action_controller',
        Time.now,
        Time.now,
        2,
        status: 200,
        controller: 'HomeController',
        action: 'index',
        format: 'application/json',
        method: 'GET',
        path: '/home?foo=bar',
        params: {},
        db_runtime: 0.02,
        view_runtime: 0.01
      )
    end

    describe 'with an exception' do
      let(:exception) { RuntimeError.new('bad request') }
      let(:backtrace) { caller }

      before do
        allow(exception).to receive(:backtrace).and_return(backtrace)
        event.payload[:exception_object] = exception
      end

      it 'adds exception data to log', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/446202' do
        subscriber.process_action(event)

        expect(log_data['exception.class']).to eq('RuntimeError')
        expect(log_data['exception.message']).to eq('bad request')
        expect(log_data['exception.backtrace']).to eq(Gitlab::BacktraceCleaner.clean_backtrace(backtrace))
      end

      context 'with an ActiveRecord::StatementInvalid' do
        let(:exception) { ActiveRecord::StatementInvalid.new(sql: 'SELECT "users".* FROM "users" WHERE "users"."id" = 1 AND "users"."foo" = $1') }

        it 'adds the SQL query to the log' do
          subscriber.process_action(event)

          expect(log_data['exception.sql']).to eq('SELECT "users".* FROM "users" WHERE "users"."id" = $2 AND "users"."foo" = $1')
        end
      end
    end

    describe 'with etag_route' do
      let(:etag_route) { 'etag route' }

      before do
        event.payload[:etag_route] = etag_route
      end

      it 'adds etag_route to log' do
        subscriber.process_action(event)

        expect(log_data['etag_route']).to eq(etag_route)
      end
    end

    describe 'with access token in url' do
      before do
        event.payload[:location] = 'http://example.com/auth.html#access_token=secret_token&token_type=Bearer'
      end

      it 'strips location from sensitive information' do
        subscriber.redirect_to(event)
        subscriber.process_action(event)

        expect(log_data['location']).not_to include('secret_token')
        expect(log_data['location']).to include('filtered')
      end

      it 'leaves non-sensitive information from location' do
        subscriber.redirect_to(event)
        subscriber.process_action(event)

        expect(log_data['location']).to include('&token_type=Bearer')
      end
    end

    context 'with db payload' do
      let(:db_load_balancing_logging_keys) do
        %w[
          db_main_wal_count
          db_main_wal_count
          db_main_wal_cached_count
          db_main_wal_cached_count
          db_main_count
          db_main_cached_count
          db_main_count
          db_main_cached_count
          db_main_duration_s
          db_main_duration_s
        ]
      end

      before do
        ApplicationRecord.connection.execute('SELECT pg_sleep(0.1);')
      end

      context 'when RequestStore is enabled', :request_store do
        it 'includes db counters' do
          subscriber.process_action(event)

          expect(log_data).to include("db_main_count" => a_value >= 1, "db_main_write_count" => 0, "db_main_cached_count" => 0)
        end
      end

      context 'when RequestStore is disabled' do
        it 'does not include db counters' do
          subscriber.process_action(event)

          expect(log_data).not_to include("db_main_count", "db_main_write_count", "db_main_cached_count")
        end
      end

      context 'with db payload' do
        context 'when RequestStore is enabled', :request_store do
          it 'includes db counters for load balancing' do
            subscriber.process_action(event)

            expect(log_data).to include(*db_load_balancing_logging_keys)
          end
        end

        context 'when RequestStore is disabled' do
          it 'does not include db counters for load balancing' do
            subscriber.process_action(event)

            expect(log_data).not_to include(*db_load_balancing_logging_keys)
          end
        end
      end
    end
  end
end
