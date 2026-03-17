# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'querying award emoji', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  let(:query) do
    <<~GQL
      {
        project(fullPath: "#{project.full_path}") {
          mergeRequest(iid: "#{merge_request.iid}") {
            awardEmoji {
              nodes {
                name
                emoji
              }
            }
          }
        }
      }
    GQL
  end

  context 'when the award emoji is a custom emoji' do
    let_it_be(:custom_emoji) { create(:custom_emoji, name: 'partyparrot', group: group) }
    let_it_be(:award_emoji) { create(:award_emoji, name: 'partyparrot', awardable: merge_request, user: user) }

    it 'returns null for the emoji field without errors' do
      post_graphql(query, current_user: user)

      award_emoji_nodes = graphql_data_at(:project, :merge_request, :award_emoji, :nodes)

      expect(award_emoji_nodes).to contain_exactly(
        a_hash_including('name' => 'partyparrot', 'emoji' => nil)
      )
    end
  end

  context 'when the award emoji is a standard emoji' do
    let_it_be(:award_emoji) { create(:award_emoji, name: 'thumbsup', awardable: merge_request, user: user) }

    it 'returns the emoji codepoints' do
      post_graphql(query, current_user: user)

      award_emoji_nodes = graphql_data_at(:project, :merge_request, :award_emoji, :nodes)

      expect(award_emoji_nodes).to contain_exactly(
        a_hash_including('name' => 'thumbsup', 'emoji' => '👍')
      )
    end
  end
end
