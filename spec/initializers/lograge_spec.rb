# frozen_string_literal: true

require 'spec_helper'

describe 'lograge', type: :request do
  let(:headers) { { 'X-Request-ID' => 'new-correlation-id' } }

  context 'for API requests' do
    subject { get("/api/v4/endpoint", {}, headers) }

    it 'logs to api_json log' do
      # we assert receiving parameters by grape logger
      expect_any_instance_of(Gitlab::GrapeLogging::Formatters::LogrageWithTimestamp).to receive(:call)
        .with(anything, anything, anything, a_hash_including("correlation_id" => "new-correlation-id"))
        .and_call_original

      subject
    end
  end

  context 'for Controller requests' do
    subject { get("/", {}, headers) }

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
  end
end
