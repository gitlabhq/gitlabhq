# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Policies::DependencyProxy::GroupPolicy, feature_category: :system_access do
  subject { described_class.new(auth_token, group.dependency_proxy_for_containers_policy_subject) }

  let_it_be(:guest) { create(:user) }
  let_it_be_with_reload(:non_group_member) { create(:user) }
  let_it_be(:group, refind: true) { create(:group, :private, :owner_subgroup_creation_only, guests: guest) }
  let_it_be(:current_user) { guest }

  describe 'dependency proxy' do
    shared_examples 'disallows dependency proxy read access' do
      it { is_expected.to be_disallowed(:read_dependency_proxy) }
    end

    shared_examples 'allows dependency proxy read access' do
      it { is_expected.to be_allowed(:read_dependency_proxy) }
    end

    context 'with feature disabled' do
      let_it_be(:auth_token) { create(:personal_access_token, user: current_user) }

      before do
        stub_config(dependency_proxy: { enabled: false })
      end

      it_behaves_like 'disallows dependency proxy read access'
    end

    context 'with feature enabled' do
      let_it_be(:auth_token) { create(:personal_access_token, user: current_user) }

      before do
        stub_config(dependency_proxy: { enabled: true }, registry: { enabled: true })
      end

      context 'with a human user personal access token' do
        subject { described_class.new(auth_token, group.dependency_proxy_for_containers_policy_subject) }

        context 'when not a member of the group' do
          let_it_be(:current_user) { non_group_member }
          let_it_be(:auth_token) { create(:personal_access_token, user: current_user) }

          it_behaves_like 'disallows dependency proxy read access'
        end

        context 'when a member of the group' do
          let_it_be(:current_user) { guest }
          let_it_be(:auth_token) { create(:personal_access_token, user: current_user) }

          it_behaves_like 'allows dependency proxy read access'
        end
      end

      context 'with a deploy token user' do
        before do
          create(:group_deploy_token, group: group, deploy_token: auth_token)
        end

        context 'with insufficient scopes' do
          let_it_be(:auth_token) { create(:deploy_token, :group, user: current_user) }

          it_behaves_like 'disallows dependency proxy read access'
        end

        context 'with sufficient scopes' do
          let_it_be(:auth_token) { create(:deploy_token, :group, :dependency_proxy_scopes) }

          it_behaves_like 'allows dependency proxy read access'
        end
      end

      context 'with a group access token user' do
        let_it_be(:bot_user) { create(:user, :project_bot) }
        let_it_be(:auth_token) do
          create(:personal_access_token, user: bot_user, scopes: [Gitlab::Auth::READ_API_SCOPE])
        end

        context 'when not a member of the group' do
          it_behaves_like 'disallows dependency proxy read access'
        end

        context 'when a member of the group' do
          before do
            group.add_guest(bot_user)
          end

          it_behaves_like 'allows dependency proxy read access'
        end
      end

      context 'with all other user types' do
        User::USER_TYPES.except(:human, :project_bot, :security_policy_bot, :placeholder).each_value do |user_type|
          context "with user_type #{user_type}" do
            let_it_be(:auth_token) { create(:personal_access_token, user: non_group_member) }

            before do
              non_group_member.update!(user_type: user_type)
            end

            context 'when the user has sufficient access' do
              before do
                group.add_guest(non_group_member)
              end

              it_behaves_like 'allows dependency proxy read access'
            end

            context 'when the user does not have sufficient access' do
              it_behaves_like 'disallows dependency proxy read access'
            end
          end
        end
      end
    end
  end
end
