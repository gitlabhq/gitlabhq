# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bitbucket::ExponentialBackoff, feature_category: :importers do
  let(:service) { dummy_class.new }
  let(:body) { 'test' }
  let(:parsed_response) { instance_double(Net::HTTPResponse, body: body.to_json) }
  let(:response) { double(Faraday::Response, body: body, parsed: parsed_response) }
  let(:response_caller) { -> { response } }

  let(:dummy_class) do
    Class.new do
      def logger
        @logger ||= Logger.new(File::NULL)
      end

      def dummy_method(response_caller)
        retry_with_exponential_backoff do
          response_caller.call
        end
      end

      include Bitbucket::ExponentialBackoff
    end
  end

  subject(:execute) { service.dummy_method(response_caller) }

  describe '.retry_with_exponential_backoff' do
    let(:max_retries) { described_class::MAX_RETRIES }

    context 'when the function succeeds on the first try' do
      it 'calls the function once and returns its result' do
        expect(response_caller).to receive(:call).once.and_call_original

        expect(Gitlab::Json.parse(execute.parsed.body)).to eq(body)
      end
    end

    context 'when the function response is an error' do
      let(:error) { 'Rate limit for this resource has been exceeded' }

      before do
        stub_const("#{described_class.name}::INITIAL_DELAY", 0.0)
        allow(Random).to receive(:rand).and_return(0.001)
      end

      shared_examples 'raises a RateLimitError' do |exception|
        it 'raises a RateLimitError if the maximum number of retries is exceeded' do
          allow(response_caller).to receive(:call).and_raise(exception, error)

          message = "Maximum number of retries (#{max_retries}) exceeded. #{error}"

          expect do
            execute
          end.to raise_error(described_class::RateLimitError, message)

          expect(response_caller).to have_received(:call).exactly(max_retries).times
        end
      end

      include_examples 'raises a RateLimitError', OAuth2::Error
      include_examples 'raises a RateLimitError', HTTParty::ResponseError
    end
  end
end
