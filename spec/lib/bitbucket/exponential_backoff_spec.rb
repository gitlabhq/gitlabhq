# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bitbucket::ExponentialBackoff, feature_category: :importers do
  let(:service) { dummy_class.new }
  let(:body) { 'test' }
  let(:parsed_response) { instance_double(Net::HTTPResponse, body: body.to_json) }
  # rubocop:disable RSpec/VerifiedDoubles -- Faraday::Response doesn't have `parsed`; it's added by OAuth2
  let(:response) { double(Faraday::Response, body: body, parsed: parsed_response) }
  # rubocop:enable RSpec/VerifiedDoubles
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

      context 'when an OAuth2::Error has a retryable status code' do
        let(:oauth_response) do
          # rubocop:disable RSpec/VerifiedDoubles -- Faraday response used to construct OAuth2::Response
          double(Faraday::Response, status: 429, headers: {}, body: error).tap do |resp|
            allow(resp).to receive(:on_complete)
          end
          # rubocop:enable RSpec/VerifiedDoubles
        end

        let(:oauth2_error) { OAuth2::Error.new(OAuth2::Response.new(oauth_response)) }

        it 'raises a RateLimitError if the maximum number of retries is exceeded' do
          allow(response_caller).to receive(:call).and_raise(oauth2_error)

          expect { execute }.to raise_error(described_class::RateLimitError)
          expect(response_caller).to have_received(:call).exactly(max_retries).times
        end
      end

      context 'when an HTTParty::ResponseError has a retryable status code' do
        let(:httparty_response) { instance_double(Net::HTTPResponse, code: '429') }
        let(:httparty_error) { HTTParty::ResponseError.new(httparty_response) }

        it 'raises a RateLimitError if the maximum number of retries is exceeded' do
          allow(response_caller).to receive(:call).and_raise(httparty_error)

          expect { execute }.to raise_error(described_class::RateLimitError)
          expect(response_caller).to have_received(:call).exactly(max_retries).times
        end
      end
    end

    context 'when an OAuth2::Error has a specific HTTP status' do
      let(:oauth_response) do
        # rubocop:disable RSpec/VerifiedDoubles -- Faraday response used to construct OAuth2::Response
        double(Faraday::Response, status: status_code, headers: {}, body: body.to_json).tap do |resp|
          allow(resp).to receive(:on_complete)
        end
        # rubocop:enable RSpec/VerifiedDoubles
      end

      let(:oauth2_error) { OAuth2::Error.new(OAuth2::Response.new(oauth_response)) }

      before do
        stub_const("#{described_class.name}::INITIAL_DELAY", 0.0)
        allow(Random).to receive(:rand).and_return(0.001)
        allow(response_caller).to receive(:call).and_raise(oauth2_error)
      end

      using RSpec::Parameterized::TableSyntax

      context 'when the status code is retryable' do
        where(:status_code) { [408, 429, 500] }

        with_them do
          it 'retries and raises a RateLimitError' do
            expect { service.dummy_method(response_caller) }.to raise_error(described_class::RateLimitError)
            expect(response_caller).to have_received(:call).exactly(max_retries).times
          end
        end
      end

      context 'when the status code is non-retryable' do
        where(:status_code) { [401, 403, 404, 410] }

        with_them do
          it 'raises OAuth2::Error immediately without retrying' do
            expect { service.dummy_method(response_caller) }.to raise_error(OAuth2::Error)
            expect(response_caller).to have_received(:call).once
          end
        end
      end
    end

    context 'when an HTTParty::ResponseError has a specific HTTP status' do
      let(:httparty_response) { instance_double(Net::HTTPResponse, code: status_code.to_s) }
      let(:httparty_error) { HTTParty::ResponseError.new(httparty_response) }

      before do
        stub_const("#{described_class.name}::INITIAL_DELAY", 0.0)
        allow(Random).to receive(:rand).and_return(0.001)
        allow(response_caller).to receive(:call).and_raise(httparty_error)
      end

      using RSpec::Parameterized::TableSyntax

      context 'when the status code is retryable' do
        where(:status_code) { [408, 429, 500] }

        with_them do
          it 'retries and raises a RateLimitError' do
            expect { service.dummy_method(response_caller) }.to raise_error(described_class::RateLimitError)
            expect(response_caller).to have_received(:call).exactly(max_retries).times
          end
        end
      end

      context 'when the status code is non-retryable' do
        where(:status_code) { [401, 403, 404, 410] }

        with_them do
          it 'raises HTTParty::ResponseError immediately without retrying' do
            expect { service.dummy_method(response_caller) }.to raise_error(HTTParty::ResponseError)
            expect(response_caller).to have_received(:call).once
          end
        end
      end
    end

    context 'when the HTTParty::ResponseError has no proper response object' do
      before do
        stub_const("#{described_class.name}::INITIAL_DELAY", 0.0)
        allow(Random).to receive(:rand).and_return(0.001)
      end

      it 'treats the error as non-retryable and raises immediately' do
        response_without_code = Object.new
        httparty_error = HTTParty::ResponseError.new(response_without_code)

        allow(response_caller).to receive(:call).and_raise(httparty_error)

        expect { execute }.to raise_error(HTTParty::ResponseError)
        expect(response_caller).to have_received(:call).once
      end
    end

    context 'when the OAuth2::Error has no proper response object' do
      before do
        stub_const("#{described_class.name}::INITIAL_DELAY", 0.0)
        allow(Random).to receive(:rand).and_return(0.001)
      end

      context 'when the response is a plain string' do
        let(:oauth2_error) { OAuth2::Error.new('unexpected error') }

        it 'treats the error as non-retryable and raises immediately' do
          allow(response_caller).to receive(:call).and_raise(oauth2_error)

          expect { execute }.to raise_error(OAuth2::Error)
          expect(response_caller).to have_received(:call).once
        end
      end

      context 'when the response is a Hash' do
        let(:oauth2_error) { OAuth2::Error.new({ error: 'A refresh_token is not available' }) }

        it 'treats the error as non-retryable and raises immediately' do
          allow(response_caller).to receive(:call).and_raise(oauth2_error)

          expect { execute }.to raise_error(OAuth2::Error)
          expect(response_caller).to have_received(:call).once
        end
      end
    end
  end

  describe '#http_status_from' do
    it 'returns nil for an unrecognized exception type' do
      expect(service.send(:http_status_from, StandardError.new('oops'))).to be_nil
    end
  end
end
