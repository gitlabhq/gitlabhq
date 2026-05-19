# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bitbucket::ApiConnection, feature_category: :importers do
  describe '#get' do
    shared_examples 'bitbucket api connection' do |username, password|
      it 'uses Gitlab::HTTP to perform GET request with basic auth' do
        expect(connection).to receive(:retry_with_exponential_backoff).and_call_original

        expect(Gitlab::HTTP)
          .to receive(:get)
          .with(
            'https://api.bitbucket.org/2.0/user',
            {
              basic_auth: { username: username, password: password },
              headers: { 'Accept' => 'application/json' },
              query: { page: 1 },
              max_bytes: an_instance_of(Integer)
            }
          )
          .and_return(
            instance_double(HTTParty::Response,
              code: 200,
              success?: true,
              parsed_response: {}
            )
          )

        connection.get('/user', page: 1)
      end

      it 'logs the retries and raises an error if it does not succeed on retry' do
        httparty_response = instance_double(Net::HTTPResponse, code: '429')
        allow(Gitlab::HTTP).to receive(:get).and_raise(HTTParty::ResponseError.new(httparty_response))
        stub_const('Bitbucket::ExponentialBackoff::INITIAL_DELAY', 0.0)
        allow(Random).to receive(:rand).and_return(0.001)

        expect(Gitlab::BitbucketImport::Logger).to receive(:info)
          .with(message: /Retrying in .+ seconds due to/)
          .twice

        expect { connection.get('/users') }.to raise_error(Bitbucket::ExponentialBackoff::RateLimitError)
      end
    end

    context 'when using API token authentication' do
      subject(:connection) { described_class.new(email: 'user@example.com', api_token: 'token123') }

      it_behaves_like 'bitbucket api connection', 'user@example.com', 'token123'
    end
  end
end
