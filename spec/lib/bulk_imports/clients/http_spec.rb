# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Clients::Http do
  include ImportSpecHelper

  let(:uri) { 'http://gitlab.example' }
  let(:token) { 'token' }
  let(:resource) { 'resource' }

  subject { described_class.new(uri: uri, token: token) }

  describe '#get' do
    let(:response_double) { double(code: 200, success?: true, parsed_response: {}) }

    shared_examples 'performs network request' do
      it 'performs network request' do
        expect(Gitlab::HTTP).to receive(:get).with(*expected_args).and_return(response_double)

        subject.get(resource)
      end
    end

    describe 'parsed response' do
      it 'returns parsed response' do
        response_double = double(code: 200, success?: true, parsed_response: [{ id: 1 }, { id: 2 }])

        allow(Gitlab::HTTP).to receive(:get).and_return(response_double)

        expect(subject.get(resource)).to eq(response_double.parsed_response)
      end
    end

    describe 'request query' do
      include_examples 'performs network request' do
        let(:expected_args) do
          [
            anything,
            hash_including(
              query: {
                page: described_class::DEFAULT_PAGE,
                per_page: described_class::DEFAULT_PER_PAGE
              }
            )
          ]
        end
      end
    end

    describe 'request headers' do
      include_examples 'performs network request' do
        let(:expected_args) do
          [
            anything,
            hash_including(
              headers: {
                'Content-Type' => 'application/json',
                'Authorization' => "Bearer #{token}"
              }
            )
          ]
        end
      end
    end

    describe 'request uri' do
      include_examples 'performs network request' do
        let(:expected_args) do
          ['http://gitlab.example:80/api/v4/resource', anything]
        end
      end
    end

    context 'error handling' do
      context 'when error occurred' do
        it 'raises ConnectionError' do
          allow(Gitlab::HTTP).to receive(:get).and_raise(Errno::ECONNREFUSED)

          expect { subject.get(resource) }.to raise_exception(described_class::ConnectionError)
        end
      end

      context 'when response is not success' do
        it 'raises ConnectionError' do
          response_double = double(code: 503, success?: false)

          allow(Gitlab::HTTP).to receive(:get).and_return(response_double)

          expect { subject.get(resource) }.to raise_exception(described_class::ConnectionError)
        end
      end
    end
  end
end
