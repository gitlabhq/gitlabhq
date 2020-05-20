# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::PhabricatorImport::Conduit::TasksResponse do
  let(:conduit_response) do
    Gitlab::PhabricatorImport::Conduit::Response
      .new(Gitlab::Json.parse(fixture_file('phabricator_responses/maniphest.search.json')))
  end

  subject(:response) { described_class.new(conduit_response) }

  describe '#pagination' do
    it 'delegates to the conduit reponse' do
      expect(response.pagination).to eq(conduit_response.pagination)
    end
  end

  describe '#tasks' do
    it 'builds the correct tasks representation' do
      tasks = response.tasks

      titles = tasks.map(&:issue_attributes).map { |attrs| attrs[:title] }

      expect(titles).to contain_exactly('Things are slow', 'Things are broken')
    end
  end
end
