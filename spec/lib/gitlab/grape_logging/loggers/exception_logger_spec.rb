# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GrapeLogging::Loggers::ExceptionLogger do
  let(:mock_request) { double('env', env: {}) }
  let(:response_body) { nil }

  describe ".parameters" do
    subject { described_class.new.parameters(mock_request, response_body) }

    describe 'when no exception is available' do
      it 'returns an empty hash' do
        expect(subject).to eq({})
      end
    end

    describe 'with a response' do
      before do
        mock_request.env[::API::Helpers::API_RESPONSE_STATUS_CODE] = code
      end

      context 'with a String response' do
        let(:response_body) { { message: "something went wrong" }.to_json }
        let(:code) { 400 }
        let(:expected) { { api_error: [response_body.to_s] } }

        it 'logs the response body' do
          expect(subject).to eq(expected)
        end
      end

      context 'with an Array response' do
        let(:response_body) { ["hello world", 1] }
        let(:code) { 400 }
        let(:expected) { { api_error: ["hello world", "1"] } }

        it 'casts all elements to strings' do
          expect(subject).to eq(expected)
        end
      end

      # Rack v2.0.9 can return a BodyProxy. This was changed in later versions:
      # https://github.com/rack/rack/blob/2.0.9/lib/rack/response.rb#L69
      context 'with a Rack BodyProxy response' do
        let(:message) { { message: "something went wrong" }.to_json }
        let(:response) { Rack::Response.new(message, code, {}) }
        let(:response_body) { Rack::BodyProxy.new(response) }
        let(:code) { 400 }
        let(:expected) { { api_error: [message] } }

        it 'logs the response body' do
          expect(subject).to eq(expected)
        end
      end

      context 'unauthorized error' do
        let(:response_body) { 'unauthorized' }
        let(:code) { 401 }

        it 'does not log an api_error field' do
          expect(subject).not_to have_key(:api_error)
        end
      end

      context 'HTTP success' do
        let(:response_body) { 'success' }
        let(:code) { 200 }

        it 'does not log an api_error field' do
          expect(subject).not_to have_key(:api_error)
        end
      end
    end

    describe 'when an exception is available' do
      let(:exception) { RuntimeError.new('This is a test') }
      let(:mock_request) do
        double('env',
          env: {
            ::API::Helpers::API_EXCEPTION_ENV => exception
          }
        )
      end

      let(:expected) do
        {
          'exception.class' => 'RuntimeError',
          'exception.message' => 'This is a test'
        }
      end

      it 'returns the correct fields' do
        expect(subject).to eq(expected)
      end

      context 'with backtrace' do
        before do
          current_backtrace = caller
          allow(exception).to receive(:backtrace).and_return(current_backtrace)
          expected['exception.backtrace'] = Rails.backtrace_cleaner.clean(current_backtrace)
        end

        it 'includes the backtrace' do
          expect(subject).to eq(expected)
        end
      end
    end
  end
end
