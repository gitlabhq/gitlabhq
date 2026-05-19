# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'UserAchievements', feature_category: :user_profile do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public, guests: user) }
  let_it_be(:achievement) { create(:achievement, namespace: group) }
  let_it_be(:non_revoked_achievement) do
    create(:user_achievement, achievement: achievement, user: user, show_on_profile: true)
  end

  let_it_be(:revoked_achievement) do
    create(:user_achievement, :revoked, achievement: achievement, user: user, show_on_profile: true)
  end

  let_it_be(:hidden_achievement) do
    create(:user_achievement, achievement: achievement, user: user, show_on_profile: false)
  end

  let_it_be(:fields) do
    <<~HEREDOC
      id
      achievements {
        count
        nodes {
          uniqueUsers {
            count
            nodes {
              username
            }
          }
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
        }
      }
    HEREDOC
  end

  let(:current_user) { user }

  let(:query) do
    graphql_query_for('namespace', { full_path: group.full_path }, fields)
  end

  before do
    post_graphql(query, current_user: current_user)
  end

  it_behaves_like 'a working graphql query'

  it 'returns all non_revoked user_achievements' do
    expect(graphql_data_at(:namespace, :achievements, :nodes, :userAchievements, :nodes))
      .to contain_exactly(
        a_graphql_entity_for(non_revoked_achievement),
        a_graphql_entity_for(hidden_achievement)
      )
  end

  it 'returns the correct achievement and user_achievement counts' do
    expect(graphql_data_at(:namespace, :achievements, :count)).to be(1)
    expect(graphql_data_at(:namespace, :achievements, :nodes, :userAchievements, :count)).to contain_exactly(2)
  end

  context 'when user_achievement has priority set' do
    let_it_be(:achievement_with_priority) do
      create(:user_achievement, achievement: achievement, user: user, priority: 0, show_on_profile: true)
    end

    let(:userquery_fields) do
      "userAchievements { nodes { id } }"
    end

    let(:query) do
      graphql_query_for('user', { username: user.username }, userquery_fields)
    end

    it 'returns achievements in correct order' do
      expect(graphql_data_at(:user, :userAchievements, :nodes).pluck('id')).to eq([
        achievement_with_priority.to_global_id.to_s,
        non_revoked_achievement.to_global_id.to_s
      ])
    end
  end

  context 'when show_on_profile is false' do
    let(:include_hidden) { false }
    let(:userquery_fields) do
      "userAchievements(includeHidden: #{include_hidden}) { nodes { id } }"
    end

    let(:query) do
      graphql_query_for('user', { username: user.username }, userquery_fields)
    end

    context 'when includeHidden is true' do
      let(:include_hidden) { true }

      context 'when current_user is achievement owner' do
        it 'returns also hidden achievements' do
          expect(graphql_data_at(:user, :userAchievements, :nodes)).to contain_exactly(
            a_graphql_entity_for(non_revoked_achievement),
            a_graphql_entity_for(hidden_achievement)
          )
        end
      end

      context 'when current_user is not the achievement owner and has no namespace membership' do
        let(:current_user) { create(:user) }

        it 'does not return hidden achievements' do
          expect(graphql_data_at(:user, :userAchievements, :nodes)).to contain_exactly(
            a_graphql_entity_for(non_revoked_achievement)
          )
        end
      end

      context 'when current_user is a maintainer of the achievement namespace' do
        let_it_be(:current_user) { create(:user, maintainer_of: group) }

        it 'returns shown and hidden achievements for that namespace' do
          # contain_exactly also guards against duplication: non_revoked_achievement must appear exactly once,
          # not twice (once from the shown branch and once from the awarder branch of the UNION).
          expect(graphql_data_at(:user, :userAchievements, :nodes)).to contain_exactly(
            a_graphql_entity_for(non_revoked_achievement),
            a_graphql_entity_for(hidden_achievement)
          )
        end
      end

      context 'when current_user is a maintainer of a parent group (inherited access)' do
        let_it_be(:parent_group, freeze: true) { create(:group) }
        let_it_be(:subgroup, freeze: true) { create(:group, parent: parent_group) }
        let_it_be(:subgroup_achievement, freeze: true) { create(:achievement, namespace: subgroup) }
        let_it_be(:hidden_subgroup_achievement, freeze: true) do
          create(:user_achievement, achievement: subgroup_achievement, user: user, show_on_profile: false)
        end

        let_it_be(:current_user, freeze: true) { create(:user, maintainer_of: parent_group) }

        let(:userquery_fields) do
          "userAchievements(includeHidden: true) { nodes { id } }"
        end

        let(:query) do
          graphql_query_for('user', { username: user.username }, userquery_fields)
        end

        it 'returns hidden achievements from the subgroup via inherited access' do
          expect(graphql_data_at(:user, :userAchievements, :nodes)).to include(
            a_graphql_entity_for(hidden_subgroup_achievement)
          )
        end
      end

      context 'when current_user has access via a group link (group-link access)' do
        let_it_be(:caller_group) { create(:group) }
        let_it_be(:current_user) { create(:user) }

        before_all do
          caller_group.add_maintainer(current_user)
          create(:group_group_link, shared_group: group, shared_with_group: caller_group,
            group_access: Gitlab::Access::MAINTAINER)
        end

        it 'returns hidden achievements from the linked group' do
          expect(graphql_data_at(:user, :userAchievements, :nodes)).to contain_exactly(
            a_graphql_entity_for(non_revoked_achievement),
            a_graphql_entity_for(hidden_achievement)
          )
        end
      end

      context 'when current_user is a maintainer of a different namespace' do
        let(:other_group) { create(:group) }
        let(:current_user) { create(:user, maintainer_of: other_group) }

        before do
          post_graphql(query, current_user: current_user)
        end

        it 'does not return hidden achievements from the original namespace' do
          expect(graphql_data_at(:user, :userAchievements, :nodes)).to contain_exactly(
            a_graphql_entity_for(non_revoked_achievement)
          )
        end
      end
    end

    it 'does not return hidden achievements' do
      expect(graphql_data_at(:user, :userAchievements, :nodes)).to contain_exactly(
        a_graphql_entity_for(non_revoked_achievement)
      )
    end
  end

  it 'can lookahead to eliminate N+1 queries', :use_clean_rails_memory_store_caching do
    control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
      post_graphql(query, current_user: user)
    end

    user2 = create(:user)
    create(:user_achievement, achievement: achievement, user: user2)

    expect { post_graphql(query, current_user: user) }.not_to exceed_all_query_limit(control)
  end

  context 'with includeHidden set to true', :use_clean_rails_memory_store_caching do
    let(:awarder) { create(:user, maintainer_of: group) }
    let(:awarder_query) do
      graphql_query_for('user', { username: user.username },
        "userAchievements(includeHidden: true) { nodes { id } }")
    end

    it 'does not exceed query limit for awarder caller' do
      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        post_graphql(awarder_query, current_user: awarder)
      end

      other_group = create(:group)
      other_achievement = create(:achievement, namespace: other_group)
      create(:user_achievement, achievement: other_achievement, user: user)

      expect { post_graphql(awarder_query, current_user: awarder) }.not_to exceed_all_query_limit(control)
    end
  end

  context 'when the achievements feature flag is disabled' do
    before do
      stub_feature_flags(achievements: false)
      post_graphql(query, current_user: user)
    end

    specify { expect(graphql_data_at(:namespace, :achievements, :nodes, :userAchievements, :nodes)).to be_empty }
  end
end
