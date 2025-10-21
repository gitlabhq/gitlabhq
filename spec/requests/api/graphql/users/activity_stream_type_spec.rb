# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ActivityStream GraphQL Query', feature_category: :user_profile do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:followed_user_1) { create(:user) }
  let_it_be(:followed_user_2) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let(:graphql_response) { post_graphql(query, current_user: user) }
  let(:activity_stream) { graphql_data_at(:current_user, :activity, :followed_users_activity, :nodes) }
  let(:query) do
    <<~GRAPHQL
      query UserActivity {
        currentUser {
          activity {
            followedUsersActivity {
              nodes {
                author {
                  name
                }
                action
                project {
                  name
                }
                target {
                  ... on Design {
                    id
                  }
                  ... on Issue {
                    title
                  }
                  ... on Note {
                    id
                  }
                  ... on MergeRequest {
                    title
                  }
                  ... on Milestone {
                    title
                  }
                  ... on Project {
                    fullPath
                  }
                  ... on Snippet {
                    title
                  }
                  ... on UserCore {
                    username
                  }
                  ... on WikiPage {
                    title
                  }
                }
              }
            }
          }
        }
      }
    GRAPHQL
  end

  before do
    user.follow(followed_user_1)
    user.follow(followed_user_2)
  end

  context 'when there are no events in the activity stream' do
    it 'returns empty nodes array' do
      graphql_response

      expect(activity_stream).to eq([])
    end
  end

  context 'when there are events in the activity stream' do
    let_it_be(:joined_project_event) { create(:event, :joined, project: project, author: followed_user_1) }
    let_it_be(:issue) { create(:issue, project: project) }
    let_it_be(:closed_issue_event) { create(:event, :closed, author: followed_user_1, project: project, target: issue) }
    let_it_be(:left_event) { create(:event, :left, author: followed_user_2, target: project) }

    it 'returns followed user\'s activity' do
      graphql_response

      expect(activity_stream).to eq(
        [
          {
            "action" => "LEFT",
            "author" => { "name" => followed_user_2.name },
            "project" => nil,
            "target" => { "fullPath" => project.full_path }
          },
          {
            "action" => "CLOSED",
            "author" => { "name" => followed_user_1.name },
            "project" => { "name" => project.name },
            "target" => { "title" => issue.title }
          },
          {
            "action" => "JOINED",
            "author" => { "name" => followed_user_1.name },
            "project" => { "name" => project.name },
            "target" => { "fullPath" => project.full_path }
          }
        ]
      )
    end
  end

  context 'when the activity_stream_graphql feature flag is disabled' do
    before do
      stub_feature_flags(activity_stream_graphql: false)
    end

    it 'returns `nil`' do
      graphql_response

      expect(activity_stream).to be_nil
    end
  end
end
