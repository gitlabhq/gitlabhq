# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query', feature_category: :groups_and_projects do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }

  let_it_be(:group_namespace) { create(:group, :private) }
  let_it_be(:public_group_namespace) { create(:group, :public) }
  let_it_be(:user_namespace) { create(:user_namespace, owner: user) }
  let_it_be(:project) { create(:project, group: group_namespace) }

  describe '.namespace' do
    subject { post_graphql(query, current_user: current_user) }

    let(:current_user) { user }

    let(:query) { graphql_query_for(:namespace, { 'fullPath' => target_namespace.full_path }, all_graphql_fields_for('Namespace')) }
    let(:query_result) { graphql_data['namespace'] }

    shared_examples 'retrieving a namespace' do
      context 'authorised query' do
        before do
          subject
        end

        it_behaves_like 'a working graphql query'

        it 'fetches the expected data' do
          expect(query_result).to include(
            'fullPath' => target_namespace.full_path,
            'name' => target_namespace.name,
            'crossProjectPipelineAvailable' => target_namespace.licensed_feature_available?(:cross_project_pipeline),
            'achievementsPath' => achievements_path
          )
        end
      end

      context 'unauthorised query' do
        before do
          subject
        end

        context 'anonymous user' do
          let(:current_user) { nil }

          it 'does not retrieve the record' do
            expect(query_result).to be_nil
          end
        end

        context 'the current user does not have permission' do
          let(:current_user) { other_user }

          it 'does not retrieve the record' do
            expect(query_result).to be_nil
          end
        end
      end
    end

    context 'when achievements feature flag is off' do
      let(:target_namespace) { public_group_namespace }

      before do
        stub_feature_flags(achievements: false)
      end

      it 'does not return achievementsPath' do
        subject
        expect(query_result).to include(
          'achievementsPath' => nil
        )
      end
    end

    context 'when used with a public group' do
      let(:target_namespace) { public_group_namespace }
      let(:achievements_path) { ::Gitlab::Routing.url_helpers.group_achievements_path(target_namespace) }

      before do
        subject
      end

      it_behaves_like 'a working graphql query'

      context 'when user is a member' do
        before do
          public_group_namespace.add_developer(user)
        end

        it 'fetches the expected data' do
          expect(query_result).to include(
            'fullPath' => target_namespace.full_path,
            'name' => target_namespace.name,
            'achievementsPath' => achievements_path
          )
        end
      end

      context 'when user is anonymous' do
        let(:current_user) { nil }

        it 'fetches the expected data' do
          expect(query_result).to include(
            'fullPath' => target_namespace.full_path,
            'name' => target_namespace.name,
            'achievementsPath' => achievements_path
          )
        end
      end

      context 'when user is not a member' do
        let(:current_user) { other_user }

        it 'fetches the expected data' do
          expect(query_result).to include(
            'fullPath' => target_namespace.full_path,
            'name' => target_namespace.name,
            'achievementsPath' => achievements_path
          )
        end
      end
    end

    context 'when used with a private namespace' do
      context 'retrieving a group' do
        it_behaves_like 'retrieving a namespace' do
          let(:target_namespace) { group_namespace }
          let(:achievements_path) { ::Gitlab::Routing.url_helpers.group_achievements_path(target_namespace) }

          before do
            group_namespace.add_developer(user)
          end
        end
      end

      context 'retrieving a user namespace' do
        it_behaves_like 'retrieving a namespace' do
          let(:target_namespace) { user_namespace }
          let(:achievements_path) { nil }
        end
      end

      context 'retrieving a project' do
        it_behaves_like 'retrieving a namespace' do
          let(:target_namespace) { project }
          let(:achievements_path) { nil }

          before do
            group_namespace.add_developer(user)
          end
        end
      end
    end
  end
end
