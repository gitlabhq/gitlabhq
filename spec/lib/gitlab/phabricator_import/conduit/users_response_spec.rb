# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::PhabricatorImport::Conduit::UsersResponse do
  let(:conduit_response) do
    Gitlab::PhabricatorImport::Conduit::Response
      .new(Gitlab::Json.parse(fixture_file('phabricator_responses/user.search.json')))
  end

  subject(:response) { described_class.new(conduit_response) }

  describe '#users' do
    it 'builds the correct users representation' do
      tasks = response.users

      usernames = tasks.map(&:username)

      expect(usernames).to contain_exactly('jane', 'john')
    end
  end
end
