# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::FogbugzImport::Interface, feature_category: :importers do
  let(:credentials) { { email: 'test@example.com', password: 'seekrit', uri: 'https://fogbugz.example.com' } }

  describe '#initialize' do
    it 'raises an exception when URI is not provided' do
      expect { described_class.new }.to raise_error(described_class::InitializationError)
    end
  end

  describe '#options' do
    it 'makes the options used to initialize the object available' do
      interface = described_class.new(credentials)
      expect(interface.options).to eq(credentials)
    end
  end

  describe '#authenticate' do
    subject(:authenticate) { described_class.new(credentials).authenticate }

    before do
      stub_request(:post, "https://fogbugz.example.com/api.asp")
        .with(
          body: "cmd=logon&email=test%40example.com&password=seekrit",
          headers: {
            'Accept' => '*/*',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'User-Agent' => 'Ruby'
          })
          .to_return(status: 200, body: server_response, headers: {})
    end

    context 'when credentials are valid' do
      let(:server_response) { '<response><token>abc123</token></response>' }

      it 'returns the token' do
        expect(authenticate).to eq('abc123')
      end
    end

    context 'when credentials are invalid' do
      let(:server_response) { '<response><error>Incorrect password or username</error></response>' }

      it 'raises an exception' do
        expect { authenticate }.to raise_error(
          Gitlab::FogbugzImport::Interface::AuthenticationError, 'Incorrect password or username'
        )
      end
    end

    context 'when server returns a blank token' do
      let(:server_response) { '<response><token></token></response>' }

      it 'raises an exception' do
        expect { authenticate }.to raise_error(Gitlab::FogbugzImport::Interface::AuthenticationError)
      end
    end
  end

  describe '#command' do
    subject(:interface) { described_class.new(credentials) }

    context 'with authentication token' do
      before do
        interface.token = 'abc123'

        stub_request(:post, "https://fogbugz.example.com/api.asp")
          .with(
            body: "cmd=search&q=case&token=abc123",
            headers: {
              'Accept' => '*/*',
              'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'User-Agent' => 'Ruby'
            })
            .to_return(status: 200, body: '<response>123</response>', headers: {})
      end

      it 'returns a result' do
        result = interface.command(:search, q: 'case')
        expect(result).to eq('123')
      end
    end

    context 'with no authentication token' do
      before do
        interface.token = nil
      end

      it 'raises an exception' do
        expect { interface.command(:search, q: 'case') }.to raise_error(
          described_class::RequestError,
          'No token available, #authenticate first'
        )
      end
    end
  end
end
