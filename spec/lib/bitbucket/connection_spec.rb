# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Bitbucket::Connection, feature_category: :integrations do
  subject(:bitbucket_connection) { described_class.new(options) }

  let(:options) do
    {
      token: 'foo',
      refresh_token: 'bar',
      expires_in: 7200
    }
  end

  describe '#connection' do
    context 'when oauth' do
      it 'uses OAuth connection' do
        expect(bitbucket_connection.connection).to be_an_instance_of(Bitbucket::OauthConnection)
      end
    end

    context 'when app password' do
      let(:options) do
        {
          username: 'foo',
          app_password: 'bar'
        }
      end

      it 'uses API connection' do
        expect(bitbucket_connection.connection).to be_an_instance_of(Bitbucket::ApiConnection)
      end

      it 'stores username and app_password' do
        connection = bitbucket_connection.connection

        expect(connection.username).to eq('foo')
        expect(connection.app_password).to eq('bar')
      end
    end

    context 'when api token' do
      let(:options) do
        {
          email: 'user@example.com',
          api_token: 'token123'
        }
      end

      it 'uses API connection' do
        expect(bitbucket_connection.connection).to be_an_instance_of(Bitbucket::ApiConnection)
      end

      it 'stores email and api_token' do
        connection = bitbucket_connection.connection

        expect(connection.email).to eq('user@example.com')
        expect(connection.api_token).to eq('token123')
      end
    end
  end

  describe '#get' do
    it 'delegates to underlying connection' do
      expect_next_instance_of(Bitbucket::OauthConnection) do |connection|
        expect(connection).to receive(:get)
      end

      bitbucket_connection.get
    end
  end
end
