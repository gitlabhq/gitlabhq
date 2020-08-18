# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraImport::ServerUsersMapperService do
  let(:start_at) { 7 }
  let(:url) { "/rest/api/2/user/search?username=''&maxResults=50&startAt=#{start_at}" }
  let(:jira_users) do
    [
      { 'key' => 'abcd', 'name' => 'user1' },
      { 'key' => 'efg' },
      { 'key' => 'hij', 'name' => 'user3', 'emailAddress' => 'user3@example.com' }
    ]
  end

  describe '#execute' do
    it_behaves_like 'mapping jira users'
  end
end
