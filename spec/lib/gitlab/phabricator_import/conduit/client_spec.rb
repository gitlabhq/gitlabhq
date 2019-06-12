# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::PhabricatorImport::Conduit::Client do
  let(:client) do
    described_class.new('https://see-ya-later.phabricator', 'api-token')
  end

  describe '#get' do
    it 'performs and parses a request' do
      params = { some: 'extra', values: %w[are passed] }
      stub_valid_request(params)

      response = client.get('test', params: params)

      expect(response).to be_a(Gitlab::PhabricatorImport::Conduit::Response)
      expect(response).to be_success
    end

    it 'wraps request errors in an `ApiError`' do
      stub_timeout

      expect { client.get('test') }.to raise_error(Gitlab::PhabricatorImport::Conduit::ApiError)
    end

    it 'raises response error' do
      stub_error_response

      expect { client.get('test') }
        .to raise_error(Gitlab::PhabricatorImport::Conduit::ResponseError, /has the wrong length/)
    end
  end

  def stub_valid_request(params = {})
    WebMock.stub_request(
      :get, 'https://see-ya-later.phabricator/api/test'
    ).with(
      body: CGI.unescape(params.reverse_merge('api.token' => 'api-token').to_query)
    ).and_return(
      status: 200,
      body: fixture_file('phabricator_responses/maniphest.search.json')
    )
  end

  def stub_timeout
    WebMock.stub_request(
      :get, 'https://see-ya-later.phabricator/api/test'
    ).to_timeout
  end

  def stub_error_response
    WebMock.stub_request(
      :get, 'https://see-ya-later.phabricator/api/test'
    ).and_return(
      status: 200,
      body: fixture_file('phabricator_responses/auth_failed.json')
    )
  end
end
