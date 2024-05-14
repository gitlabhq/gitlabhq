# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'UserAchievements', feature_category: :user_profile do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :private, guests: user) }
  let_it_be(:achievement) { create(:achievement, namespace: group) }
  let_it_be(:non_revoked_achievement) { create(:user_achievement, achievement: achievement, user: user) }
  let_it_be(:revoked_achievement) { create(:user_achievement, :revoked, achievement: achievement, user: user) }
  let_it_be(:fields) do
    <<~HEREDOC
    userAchievements {
      count
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
    HEREDOC
  end

  let_it_be(:query) do
    graphql_query_for('user', { id: user.to_global_id.to_s }, fields)
  end

  let(:current_user) { user }

  before do
    post_graphql(query, current_user: current_user)
  end

  it_behaves_like 'a working graphql query'

  it 'returns all non_revoked user_achievements' do
    expect(graphql_data_at(:user, :userAchievements, :nodes)).to contain_exactly(
      a_graphql_entity_for(non_revoked_achievement)
    )
  end

  it 'returns the correct user_achievement count' do
    expect(graphql_data_at(:user, :userAchievements, :count)).to be(1)
  end

  it 'can lookahead to eliminate N+1 queries', :use_clean_rails_memory_store_caching do
    control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
      post_graphql(query, current_user: user)
    end

    achievement2 = create(:achievement, namespace: group)
    create_list(:user_achievement, 2, achievement: achievement2, user: user)

    expect { post_graphql(query, current_user: user) }.not_to exceed_all_query_limit(control)
  end

  context 'when the achievements feature flag is disabled for a namespace' do
    let_it_be(:group2) { create(:group) }
    let_it_be(:achievement2) { create(:achievement, namespace: group2) }
    let_it_be(:user_achievement2) { create(:user_achievement, achievement: achievement2, user: user) }

    before do
      stub_feature_flags(achievements: false)
      stub_feature_flags(achievements: group2)
      post_graphql(query, current_user: current_user)
    end

    it 'does not return user_achievements for that namespace' do
      expect(graphql_data_at(:user, :userAchievements, :nodes)).to contain_exactly(
        a_graphql_entity_for(user_achievement2)
      )
    end
  end

  context 'when current user is not a member of the private group' do
    let(:current_user) { create(:user) }

    it 'returns no achievements' do
      expect(graphql_data_at(:user, :userAchievements, :nodes)).to be_empty
    end
  end
end
