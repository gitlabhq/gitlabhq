# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::PhabricatorImport::Conduit::Response do
  let(:response) { described_class.new(Gitlab::Json.parse(fixture_file('phabricator_responses/maniphest.search.json')))}
  let(:error_response) { described_class.new(Gitlab::Json.parse(fixture_file('phabricator_responses/auth_failed.json'))) }

  describe '.parse!' do
    it 'raises a ResponseError if the http response was not successfull' do
      fake_response = double(:http_response, success?: false, status: 401)

      expect { described_class.parse!(fake_response) }
        .to raise_error(Gitlab::PhabricatorImport::Conduit::ResponseError, /responded with 401/)
    end

    it 'raises a ResponseError if the response contained a Phabricator error' do
      fake_response = double(:http_response,
                             success?: true,
                             status: 200,
                             body: fixture_file('phabricator_responses/auth_failed.json'))

      expect { described_class.parse!(fake_response) }
        .to raise_error(Gitlab::PhabricatorImport::Conduit::ResponseError, /ERR-INVALID-AUTH: API token/)
    end

    it 'raises a ResponseError if JSON parsing failed' do
      fake_response = double(:http_response,
                       success?: true,
                       status: 200,
                       body: 'This is no JSON')

      expect { described_class.parse!(fake_response) }
        .to raise_error(Gitlab::PhabricatorImport::Conduit::ResponseError, /unexpected character/)
    end

    it 'returns a parsed response for valid input' do
      fake_response = double(:http_response,
                       success?: true,
                       status: 200,
                       body: fixture_file('phabricator_responses/maniphest.search.json'))

      expect(described_class.parse!(fake_response)).to be_a(described_class)
    end
  end

  describe '#success?' do
    it { expect(response).to be_success }
    it { expect(error_response).not_to be_success }
  end

  describe '#error_code' do
    it { expect(error_response.error_code).to eq('ERR-INVALID-AUTH') }
    it { expect(response.error_code).to be_nil }
  end

  describe '#error_info' do
    it 'returns the correct error info' do
      expected_message = 'API token "api-token" has the wrong length. API tokens should be 32 characters long.'

      expect(error_response.error_info).to eq(expected_message)
    end

    it { expect(response.error_info).to be_nil }
  end

  describe '#data' do
    it { expect(error_response.data).to be_nil }
    it { expect(response.data).to be_an(Array) }
  end

  describe '#pagination' do
    it { expect(error_response.pagination).to be_nil }

    it 'builds the pagination correctly' do
      expect(response.pagination).to be_a(Gitlab::PhabricatorImport::Conduit::Pagination)
      expect(response.pagination.next_page).to eq('284')
    end
  end
end
