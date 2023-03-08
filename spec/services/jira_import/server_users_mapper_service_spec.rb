# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraImport::ServerUsersMapperService, feature_category: :integrations do
  let(:start_at) { 7 }
  let(:url) { "/rest/api/2/user/search?username=''&maxResults=50&startAt=#{start_at}" }

  let_it_be(:user_1) { create(:user, username: 'randomuser', name: 'USER-name1', email: 'uji@example.com') }
  let_it_be(:user_2) { create(:user, username: 'username-2') }
  let_it_be(:user_5) { create(:user, username: 'username-5') }
  let_it_be(:user_4) { create(:user, email: 'user-4@example.com') }
  let_it_be(:user_6) { create(:user, email: 'user-6@example.com') }
  let_it_be(:user_7) { create(:user, username: 'username-7') }
  let_it_be(:user_8) do
    create(:user).tap { |user| create(:email, user: user, email: 'user8_email@example.com') }
  end

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group)        { create(:group) }
  let_it_be(:project)      { create(:project, group: group) }

  let(:jira_users) do
    [
      { 'key' => 'abcd', 'name' => 'User-Name1' }, # matched by name
      { 'key' => 'efg', 'name' => 'username-2' }, # matcher by username
      { 'key' => 'hij' }, # no match
      { 'key' => '123', 'name' => 'user-4', 'emailAddress' => 'user-4@example.com' }, # matched by email
      { 'key' => '456', 'name' => 'username5foo', 'emailAddress' => 'user-5@example.com' }, # no match
      { 'key' => '789', 'name' => 'user-6', 'emailAddress' => 'user-6@example.com' }, # matched by email, no project member
      { 'key' => 'xyz', 'name' => 'username-7', 'emailAddress' => 'user-7@example.com' }, # matched by username, no project member
      { 'key' => 'vhk', 'name' => 'user-8', 'emailAddress' => 'user8_email@example.com' }, # matched by secondary email
      { 'key' => 'uji', 'name' => 'user-9', 'emailAddress' => 'uji@example.com' } # matched by email, same as user_1
    ]
  end

  describe '#execute' do
    before do
      project.add_developer(current_user)
      project.add_developer(user_1)
      project.add_developer(user_2)
      group.add_developer(user_4)
      group.add_guest(user_8)
    end

    it_behaves_like 'mapping jira users'
  end
end
