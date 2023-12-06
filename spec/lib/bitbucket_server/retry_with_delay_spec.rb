# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BitbucketServer::RetryWithDelay, feature_category: :importers do
  let(:service) { dummy_class.new }
  let(:body) { 'test' }
  let(:response) { instance_double(HTTParty::Response, body: body, code: 200) }
  let(:response_caller) { -> { response } }

  let(:dummy_class) do
    Class.new do
      def logger
        @logger ||= Logger.new(File::NULL)
      end

      def dummy_method(response_caller)
        retry_with_delay do
          response_caller.call
        end
      end

      include BitbucketServer::RetryWithDelay
    end
  end

  subject(:execute) { service.dummy_method(response_caller) }

  describe '.retry_with_delay' do
    context 'when the function succeeds on the first try' do
      it 'calls the function once and returns its result' do
        expect(response_caller).to receive(:call).once.and_call_original

        execute
      end
    end

    context 'when the request has a status code of 429' do
      let(:headers) { { 'retry-after' => '0' } }
      let(:body) { 'HTTP Status 429 - Too Many Requests' }
      let(:response) { instance_double(HTTParty::Response, body: body, code: 429, headers: headers) }

      before do
        stub_const("#{described_class}::MAXIMUM_DELAY", 0)
      end

      it 'calls the function again after a delay' do
        expect(response_caller).to receive(:call).twice.and_call_original

        expect_next_instance_of(Logger) do |logger|
          expect(logger).to receive(:info)
            .with(message: 'Retrying in 0 seconds due to 429 Too Many Requests')
            .once
        end

        execute
      end
    end
  end
end
