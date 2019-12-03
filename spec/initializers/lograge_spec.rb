# frozen_string_literal: true

require 'spec_helper'

describe 'lograge', type: :request do
  let(:headers) { { 'X-Request-ID' => 'new-correlation-id' } }

  context 'for API requests' do
    subject { get("/api/v4/endpoint", params: {}, headers: headers) }

    it 'logs to api_json log' do
      # we assert receiving parameters by grape logger
      expect_any_instance_of(Gitlab::GrapeLogging::Formatters::LogrageWithTimestamp).to receive(:call)
        .with(anything, anything, anything, a_hash_including("correlation_id" => "new-correlation-id"))
        .and_call_original

      subject
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
        .with(a_hash_including(cpu_s: 0.1111115))
        .and_call_original

      expect(Lograge.logger).to receive(:send)
        .with(anything, include('"cpu_s":0.1111115'))
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
  end

  context 'with a log subscriber' do
    let(:subscriber) { Lograge::RequestLogSubscriber.new }

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

    let(:log_output) { StringIO.new }
    let(:logger) do
      Logger.new(log_output).tap { |logger| logger.formatter = ->(_, _, _, msg) { msg } }
    end

    describe 'with an exception' do
      let(:exception) { RuntimeError.new('bad request') }
      let(:backtrace) { caller }

      before do
        allow(exception).to receive(:backtrace).and_return(backtrace)
        event.payload[:exception_object] = exception
        Lograge.logger = logger
      end

      it 'adds exception data to log' do
        subscriber.process_action(event)

        log_data = JSON.parse(log_output.string)

        expect(log_data['exception.class']).to eq('RuntimeError')
        expect(log_data['exception.message']).to eq('bad request')
        expect(log_data['exception.backtrace']).to eq(Gitlab::Profiler.clean_backtrace(backtrace))
      end
    end
  end
end
