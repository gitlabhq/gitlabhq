# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::PhabricatorImport::Conduit::Maniphest do
  let(:maniphest) do
    described_class.new(phabricator_url: 'https://see-ya-later.phabricator', api_token: 'api-token')
  end

  describe '#tasks' do
    let(:fake_client) { double('Phabricator client') }

    before do
      allow(maniphest).to receive(:client).and_return(fake_client)
    end

    it 'calls the api with the correct params' do
      expected_params = {
        after: '123',
        attachments: {
          projects: 1, subscribers: 1, columns: 1
        }
      }

      expect(fake_client).to receive(:get).with('maniphest.search',
                                                params: expected_params)

      maniphest.tasks(after: '123')
    end

    it 'returns a parsed response' do
      response = Gitlab::PhabricatorImport::Conduit::Response
                   .new(fixture_file('phabricator_responses/maniphest.search.json'))

      allow(fake_client).to receive(:get).and_return(response)

      expect(maniphest.tasks).to be_a(Gitlab::PhabricatorImport::Conduit::TasksResponse)
    end
  end
end
