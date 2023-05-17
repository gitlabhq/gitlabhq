# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'UserAchievements', feature_category: :user_profile do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:achievement) { create(:achievement, namespace: group) }
  let_it_be(:non_revoked_achievement1) { create(:user_achievement, achievement: achievement, user: user) }
  let_it_be(:non_revoked_achievement2) { create(:user_achievement, :revoked, achievement: achievement, user: user) }
  let_it_be(:fields) do
    <<~HEREDOC
      id
      achievements {
        nodes {
          userAchievements {
            nodes {
              id
              achievement {
                id
              }
              user {
                id
              }
              awardedByUser {
                id
              }
              revokedByUser {
                id
              }
            }
          }
        }
      }
    HEREDOC
  end

  let_it_be(:query) do
    graphql_query_for('namespace', { full_path: group.full_path }, fields)
  end

  before_all do
    group.add_guest(user)
  end

  before do
    post_graphql(query, current_user: user)
  end

  it_behaves_like 'a working graphql query'

  it 'returns all non_revoked user_achievements' do
    expect(graphql_data_at(:namespace, :achievements, :nodes, :userAchievements, :nodes))
      .to contain_exactly(
        a_graphql_entity_for(non_revoked_achievement1)
      )
  end

  it 'can lookahead to eliminate N+1 queries', :use_clean_rails_memory_store_caching do
    control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) do
      post_graphql(query, current_user: user)
    end.count

    user2 = create(:user)
    create(:user_achievement, achievement: achievement, user: user2)

    expect { post_graphql(query, current_user: user) }.not_to exceed_all_query_limit(control_count)
  end

  context 'when the achievements feature flag is disabled' do
    before do
      stub_feature_flags(achievements: false)
      post_graphql(query, current_user: user)
    end

    specify { expect(graphql_data_at(:namespace, :achievements, :nodes, :userAchievements, :nodes)).to be_empty }
  end
end
