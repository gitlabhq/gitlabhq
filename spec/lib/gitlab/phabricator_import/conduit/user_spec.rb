# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::PhabricatorImport::Conduit::User do
  let(:user_client) do
    described_class.new(phabricator_url: 'https://see-ya-later.phabricator', api_token: 'api-token')
  end

  describe '#users' do
    let(:fake_client) { double('Phabricator client') }

    before do
      allow(user_client).to receive(:client).and_return(fake_client)
    end

    it 'calls the api with the correct params' do
      expected_params = {
         constraints: { phids: %w[phid-1 phid-2] }
      }

      expect(fake_client).to receive(:get).with('user.search',
                                                params: expected_params)

      user_client.users(%w[phid-1 phid-2])
    end

    it 'returns an array of parsed responses' do
      response = Gitlab::PhabricatorImport::Conduit::Response
                   .new(fixture_file('phabricator_responses/user.search.json'))

      allow(fake_client).to receive(:get).and_return(response)

      expect(user_client.users(%w[some phids])).to match_array([an_instance_of(Gitlab::PhabricatorImport::Conduit::UsersResponse)])
    end

    it 'performs multiple requests if more phids than the maximum page size are passed' do
      stub_const('Gitlab::PhabricatorImport::Conduit::User::MAX_PAGE_SIZE', 1)
      first_params = { constraints: { phids: ['phid-1'] } }
      second_params = { constraints: { phids: ['phid-2'] } }

      expect(fake_client).to receive(:get).with('user.search',
                                                params: first_params).once
      expect(fake_client).to receive(:get).with('user.search',
                                                params: second_params).once

      user_client.users(%w[phid-1 phid-2])
    end
  end
end
