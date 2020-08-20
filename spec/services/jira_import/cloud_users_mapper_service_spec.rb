# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraImport::CloudUsersMapperService do
  let(:start_at) { 7 }
  let(:url) { "/rest/api/2/users?maxResults=50&startAt=#{start_at}" }
  let(:jira_users) do
    [
      { 'accountId' => 'abcd', 'displayName' => 'user1' },
      { 'accountId' => 'efg' },
      { 'accountId' => 'hij', 'displayName' => 'user3', 'emailAddress' => 'user3@example.com' }
    ]
  end

  describe '#execute' do
    it_behaves_like 'mapping jira users'
  end
end
