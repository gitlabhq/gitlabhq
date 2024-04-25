# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bitbucket::AppPasswordConnection, feature_category: :importers do
  subject(:connection) { described_class.new(username: 'foo', app_password: 'bar') }

  describe '#get' do
    it 'uses Gitlab::HTTP to perform GET request' do
      expect(connection).to receive(:retry_with_exponential_backoff).and_call_original

      expect(Gitlab::HTTP)
        .to receive(:get)
        .with(
          'https://api.bitbucket.org/2.0/user',
          basic_auth: { username: 'foo', password: 'bar' },
          headers: { 'Accept' => 'application/json' },
          query: { page: 1 }
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
      allow(Gitlab::HTTP).to receive(:get).and_raise(HTTParty::ResponseError, 'some error')
      stub_const('Bitbucket::ExponentialBackoff::INITIAL_DELAY', 0.0)
      allow(Random).to receive(:rand).and_return(0.001)

      expect(Gitlab::BitbucketImport::Logger).to receive(:info)
        .with(message: 'Retrying in 0.0 seconds due to some error')
        .twice

      expect { connection.get('/users') }.to raise_error(Bitbucket::ExponentialBackoff::RateLimitError)
    end
  end
end
