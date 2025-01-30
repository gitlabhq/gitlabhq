# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupPolicy, feature_category: :system_access do
  include AdminModeHelper
  include_context 'GroupPolicy context'
  using RSpec::Parameterized::TableSyntax

  context 'public group with no user' do
    let(:group) { create(:group, :public) }
    let(:current_user) { nil }

    specify do
      expect_allowed(*public_permissions)
      expect_disallowed(:upload_file)
      expect_disallowed(*(guest_permissions - public_permissions))
      expect_disallowed(*(planner_permissions - guest_permissions))
      expect_disallowed(*reporter_permissions)
      expect_disallowed(*developer_permissions)
      expect_disallowed(*maintainer_permissions)
      expect_disallowed(*owner_permissions)
      expect_disallowed(:read_namespace_via_membership)
    end
  end

  context 'public group with user who is not a member' do
    let(:group) { create(:group, :public) }
    let(:current_user) { create(:user) }

    specify do
      expect_allowed(*public_permissions)
      expect_disallowed(:upload_file)
      expect_disallowed(*(guest_permissions - public_permissions))
      expect_disallowed(*(planner_permissions - guest_permissions))
      expect_disallowed(*reporter_permissions)
      expect_disallowed(*developer_permissions)
      expect_disallowed(*maintainer_permissions)
      expect_disallowed(*owner_permissions)
      expect_disallowed(:read_namespace_via_membership)
    end
  end

  context 'private group that has been invited to a public project and with no user' do
    let(:project) { create(:project, :public, group: create(:group)) }
    let(:current_user) { nil }

    before do
      create(:project_group_link, project: project, group: group)
    end

    specify do
      expect_disallowed(*public_permissions)
      expect_disallowed(*guest_permissions)
      expect_disallowed(*planner_permissions)
      expect_disallowed(*reporter_permissions)
      expect_disallowed(*owner_permissions)
    end
  end

  context 'private group that has been invited to a public project and with a foreign user' do
    let(:project) { create(:project, :public, group: create(:group)) }
    let(:current_user) { create(:user) }

    before do
      create(:project_group_link, project: project, group: group)
    end

    specify do
      expect_disallowed(*public_permissions)
      expect_disallowed(*guest_permissions)
      expect_disallowed(*planner_permissions)
      expect_disallowed(*reporter_permissions)
      expect_disallowed(*owner_permissions)
    end
  end

  context 'has projects' do
    let(:current_user) { create(:user) }
    let(:project) { create(:project, namespace: group) }

    before do
      project.add_developer(current_user)
    end

    it { expect_allowed(*(public_permissions - [:read_counts])) }

    context 'in subgroups' do
      let(:subgroup) { create(:group, :private, parent: group) }
      let(:project) { create(:project, namespace: subgroup) }

      it { expect_allowed(*(public_permissions - [:read_counts])) }
    end
  end

  shared_examples 'deploy token does not get confused with user' do
    before do
      deploy_token.update!(id: user_id)
    end

    let(:deploy_token) { create(:deploy_token) }
    let(:current_user) { deploy_token }

    specify do
      expect_disallowed(*public_permissions)
      expect_disallowed(*guest_permissions)
      expect_disallowed(*planner_permissions)
      expect_disallowed(*reporter_permissions)
      expect_disallowed(*developer_permissions)
      expect_disallowed(*maintainer_permissions)
      expect_disallowed(*owner_permissions)
    end
  end

  context 'guests' do
    let(:current_user) { guest }

    specify do
      expect_allowed(*public_permissions)
      expect_allowed(*guest_permissions)
      expect_disallowed(*(planner_permissions - guest_permissions))
      expect_disallowed(*reporter_permissions)
      expect_disallowed(*developer_permissions)
      expect_disallowed(*maintainer_permissions)
      expect_disallowed(*owner_permissions)
    end

    it_behaves_like 'deploy token does not get confused with user' do
      let(:user_id) { guest.id }
    end
  end

  context 'planners' do
    let(:current_user) { planner }

    specify do
      expect_allowed(*public_permissions)
      expect_allowed(*guest_permissions)
      expect_allowed(*planner_permissions)
      expect_disallowed(*(reporter_permissions - planner_permissions))
      expect_disallowed(*developer_permissions)
      expect_disallowed(*maintainer_permissions)
      expect_disallowed(*(owner_permissions - [:destroy_issue]))
    end

    it_behaves_like 'deploy token does not get confused with user' do
      let(:user_id) { planner.id }
    end
  end

  context 'reporter' do
    let(:current_user) { reporter }

    specify do
      expect_allowed(*public_permissions)
      expect_allowed(*guest_permissions)
      expect_allowed(*(planner_permissions - [:destroy_issue]))
      expect_allowed(*reporter_permissions)
      expect_disallowed(*developer_permissions)
      expect_disallowed(*maintainer_permissions)
      expect_disallowed(*owner_permissions)
    end

    it_behaves_like 'deploy token does not get confused with user' do
      let(:user_id) { reporter.id }
    end
  end

  context 'developer' do
    let(:current_user) { developer }

    specify do
      expect_allowed(*public_permissions)
      expect_allowed(*guest_permissions)
      expect_allowed(*(planner_permissions - [:destroy_issue]))
      expect_allowed(*reporter_permissions)
      expect_allowed(*developer_permissions)
      expect_disallowed(*maintainer_permissions)
      expect_disallowed(*owner_permissions)
    end

    it_behaves_like 'deploy token does not get confused with user' do
      let(:user_id) { developer.id }
    end
  end

  context 'maintainer' do
    let(:current_user) { maintainer }

    context 'with subgroup_creation level set to maintainer' do
      before do
        group.update!(subgroup_creation_level: ::Gitlab::Access::MAINTAINER_SUBGROUP_ACCESS)
      end

      it 'allows permissions from lower roles' do
        expect_allowed(*public_permissions)
        expect_allowed(*guest_permissions)
        expect_allowed(*(planner_permissions - [:destroy_issue]))
        expect_allowed(*reporter_permissions)
        expect_allowed(*developer_permissions)
      end

      it 'allows every maintainer permission plus creating subgroups' do
        expect_allowed(:create_subgroup, *maintainer_permissions)
        expect_disallowed(*(owner_permissions - [:create_subgroup]))
      end
    end

    context 'with subgroup_creation_level set to owner' do
      it 'allows every maintainer permission' do
        expect_allowed(*public_permissions)
        expect_allowed(*guest_permissions)
        expect_allowed(*planner_permissions - [:destroy_issue])
        expect_allowed(*reporter_permissions)
        expect_allowed(*developer_permissions)
        expect_allowed(*maintainer_permissions)
        expect_disallowed(*owner_permissions)
      end
    end

    it_behaves_like 'deploy token does not get confused with user' do
      let(:user_id) { maintainer.id }
    end
  end

  context 'owner' do
    let(:current_user) { owner }

    specify do
      expect_allowed(*public_permissions)
      expect_allowed(*guest_permissions)
      expect_allowed(*planner_permissions)
      expect_allowed(*reporter_permissions)
      expect_allowed(*developer_permissions)
      expect_allowed(*maintainer_permissions)
      expect_allowed(*owner_permissions)
    end

    it_behaves_like 'deploy token does not get confused with user' do
      let(:user_id) { owner.id }
    end
  end

  context 'admin' do
    let(:current_user) { admin }

    specify do
      expect_disallowed(*public_permissions)
      expect_disallowed(*guest_permissions)
      expect_disallowed(*planner_permissions)
      expect_disallowed(*reporter_permissions)
      expect_disallowed(*developer_permissions)
      expect_disallowed(*maintainer_permissions)
      expect_disallowed(*owner_permissions)
    end

    context 'with admin mode', :enable_admin_mode do
      specify do
        expect_allowed(*public_permissions)
        expect_allowed(*guest_permissions)
        expect_allowed(*planner_permissions)
        expect_allowed(*reporter_permissions)
        expect_allowed(*developer_permissions)
        expect_allowed(*maintainer_permissions)
        expect_allowed(*owner_permissions)
        expect_allowed(*admin_permissions)
      end
    end

    it_behaves_like 'deploy token does not get confused with user' do
      let(:user_id) { admin.id }

      context 'with admin mode', :enable_admin_mode do
        it { expect_disallowed(*admin_permissions) }
      end
    end
  end

  context 'organization owner' do
    let(:current_user) { organization_owner }

    specify do
      expect_allowed(*public_permissions)
      expect_allowed(*guest_permissions)
      expect_allowed(*planner_permissions)
      expect_allowed(*reporter_permissions)
      expect_allowed(*developer_permissions)
      expect_allowed(*maintainer_permissions)
      expect_allowed(*owner_permissions)
      expect_allowed(*admin_permissions)
    end

    context 'when user is also an admin' do
      before do
        organization_owner.update!(admin: true)
      end

      it { expect_disallowed(:admin_organization) }

      context 'with admin mode', :enable_admin_mode do
        it { expect_allowed(:admin_organization) }
      end
    end
  end

  context 'migration bot' do
    let_it_be(:migration_bot) { Users::Internal.migration_bot }
    let_it_be(:current_user) { migration_bot }

    it :aggregate_failures do
      expect_allowed(:read_resource_access_tokens, :destroy_resource_access_tokens)
      expect_disallowed(*guest_permissions)
      expect_disallowed(*planner_permissions)
      expect_disallowed(*reporter_permissions)
      expect_disallowed(*developer_permissions)
      expect_disallowed(*maintainer_permissions)
      expect_disallowed(*owner_permissions)
    end

    it_behaves_like 'deploy token does not get confused with user' do
      let(:user_id) { migration_bot.id }
    end

    context 'with no user' do
      let(:current_user) { nil }

      it :aggregate_failures do
        expect_disallowed(:read_resource_access_tokens, :destroy_resource_access_tokens)
        expect_disallowed(*guest_permissions)
        expect_disallowed(*planner_permissions)
        expect_disallowed(*reporter_permissions)
        expect_disallowed(*developer_permissions)
        expect_disallowed(*maintainer_permissions)
        expect_disallowed(*owner_permissions)
      end
    end
  end

  describe 'private nested group use the highest access level from the group and inherited permissions' do
    let_it_be(:nested_group) do
      create(:group, :private, :owner_subgroup_creation_only, parent: group)
    end

    before_all do
      nested_group.add_guest(guest)
      nested_group.add_guest(reporter)
      nested_group.add_guest(developer)
      nested_group.add_guest(maintainer)

      group.owners.destroy_all # rubocop: disable Cop/DestroyAll

      group.add_guest(owner)
      nested_group.add_owner(owner)
    end

    subject { described_class.new(current_user, nested_group) }

    context 'with no user' do
      let(:current_user) { nil }

      specify do
        expect_disallowed(*public_permissions)
        expect_disallowed(*guest_permissions)
        expect_disallowed(*planner_permissions)
        expect_disallowed(*reporter_permissions)
        expect_disallowed(*developer_permissions)
        expect_disallowed(*maintainer_permissions)
        expect_disallowed(*owner_permissions)
      end
    end

    context 'guests' do
      let(:current_user) { guest }

      specify do
        expect_allowed(*public_permissions)
        expect_allowed(*guest_permissions)
        expect_disallowed(*(planner_permissions - guest_permissions))
        expect_disallowed(*reporter_permissions)
        expect_disallowed(*developer_permissions)
        expect_disallowed(*maintainer_permissions)
        expect_disallowed(*owner_permissions)
      end
    end

    context 'planners' do
      let(:current_user) { planner }

      specify do
        expect_allowed(*public_permissions)
        expect_allowed(*guest_permissions)
        expect_allowed(*planner_permissions)
        expect_disallowed(*(reporter_permissions - planner_permissions))
        expect_disallowed(*developer_permissions)
        expect_disallowed(*maintainer_permissions)
        expect_disallowed(*(owner_permissions - [:destroy_issue]))
      end
    end

    context 'reporter' do
      let(:current_user) { reporter }

      specify do
        expect_allowed(*public_permissions)
        expect_allowed(*guest_permissions)
        expect_allowed(*(planner_permissions - [:destroy_issue]))
        expect_allowed(*reporter_permissions)
        expect_disallowed(*developer_permissions)
        expect_disallowed(*maintainer_permissions)
        expect_disallowed(*owner_permissions)
      end
    end

    context 'developer' do
      let(:current_user) { developer }

      specify do
        expect_allowed(*public_permissions)
        expect_allowed(*guest_permissions)
        expect_allowed(*(planner_permissions - [:destroy_issue]))
        expect_allowed(*reporter_permissions)
        expect_allowed(*developer_permissions)
        expect_disallowed(*maintainer_permissions)
        expect_disallowed(*owner_permissions)
      end
    end

    context 'maintainer' do
      let(:current_user) { maintainer }

      specify do
        expect_allowed(*public_permissions)
        expect_allowed(*guest_permissions)
        expect_allowed(*(planner_permissions - [:destroy_issue]))
        expect_allowed(*reporter_permissions)
        expect_allowed(*developer_permissions)
      end

      it 'allows every maintainer permission plus creating subgroups' do
        expect_allowed(*maintainer_permissions)
        expect_disallowed(*owner_permissions)
      end
    end

    context 'owner' do
      let(:current_user) { owner }

      specify do
        expect_allowed(*public_permissions)
        expect_allowed(*guest_permissions)
        expect_allowed(*planner_permissions)
        expect_allowed(*reporter_permissions)
        expect_allowed(*developer_permissions)
        expect_allowed(*maintainer_permissions)
        expect_allowed(*owner_permissions)
      end
    end
  end

  describe 'change_share_with_group_lock' do
    context 'when the current_user owns the group' do
      let(:current_user) { owner }

      context 'when the group share_with_group_lock is enabled' do
        let(:group) { create(:group, share_with_group_lock: true, parent: parent) }

        before do
          group.add_owner(owner)
        end

        context 'when the parent group share_with_group_lock is enabled' do
          context 'when the group has a grandparent' do
            let(:parent) { create(:group, share_with_group_lock: true, parent: grandparent) }

            context 'when the grandparent share_with_group_lock is enabled' do
              let(:grandparent) { create(:group, share_with_group_lock: true) }

              context 'when the current_user owns the parent' do
                before do
                  parent.add_owner(current_user)
                end

                context 'when the current_user owns the grandparent' do
                  before do
                    grandparent.add_owner(current_user)
                  end

                  it { expect_allowed(:change_share_with_group_lock) }
                end

                context 'when the current_user does not own the grandparent' do
                  it { expect_disallowed(:change_share_with_group_lock) }
                end
              end

              context 'when the current_user does not own the parent' do
                it { expect_disallowed(:change_share_with_group_lock) }
              end
            end

            context 'when the grandparent share_with_group_lock is disabled' do
              let(:grandparent) { create(:group) }

              context 'when the current_user owns the parent' do
                before do
                  parent.add_owner(current_user)
                end

                it { expect_allowed(:change_share_with_group_lock) }
              end

              context 'when the current_user does not own the parent' do
                it { expect_disallowed(:change_share_with_group_lock) }
              end
            end
          end

          context 'when the group does not have a grandparent' do
            let(:parent) { create(:group, share_with_group_lock: true) }

            context 'when the current_user owns the parent' do
              before do
                parent.add_owner(current_user)
              end

              it { expect_allowed(:change_share_with_group_lock) }
            end

            context 'when the current_user does not own the parent' do
              it { expect_disallowed(:change_share_with_group_lock) }
            end
          end
        end

        context 'when the parent group share_with_group_lock is disabled' do
          let(:parent) { create(:group) }

          it { expect_allowed(:change_share_with_group_lock) }
        end
      end

      context 'when the group share_with_group_lock is disabled' do
        it { expect_allowed(:change_share_with_group_lock) }
      end
    end

    context 'when the current_user does not own the group' do
      let(:current_user) { create(:user) }

      it { expect_disallowed(:change_share_with_group_lock) }
    end
  end

  context 'transfer_projects' do
    shared_examples_for 'allowed to transfer projects' do
      before do
        group.update!(project_creation_level: project_creation_level)
      end

      it { is_expected.to be_allowed(:transfer_projects) }
    end

    shared_examples_for 'not allowed to transfer projects' do
      before do
        group.update!(project_creation_level: project_creation_level)
      end

      it { is_expected.to be_disallowed(:transfer_projects) }
    end

    context 'reporter' do
      let(:current_user) { reporter }

      it_behaves_like 'not allowed to transfer projects' do
        let(:project_creation_level) { ::Gitlab::Access::NO_ONE_PROJECT_ACCESS }
      end

      it_behaves_like 'not allowed to transfer projects' do
        let(:project_creation_level) { ::Gitlab::Access::OWNER_PROJECT_ACCESS }
      end

      it_behaves_like 'not allowed to transfer projects' do
        let(:project_creation_level) { ::Gitlab::Access::MAINTAINER_PROJECT_ACCESS }
      end

      it_behaves_like 'not allowed to transfer projects' do
        let(:project_creation_level) { ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS }
      end
    end

    context 'developer' do
      let(:current_user) { developer }

      it_behaves_like 'not allowed to transfer projects' do
        let(:project_creation_level) { ::Gitlab::Access::NO_ONE_PROJECT_ACCESS }
      end

      it_behaves_like 'not allowed to transfer projects' do
        let(:project_creation_level) { ::Gitlab::Access::OWNER_PROJECT_ACCESS }
      end

      it_behaves_like 'not allowed to transfer projects' do
        let(:project_creation_level) { ::Gitlab::Access::MAINTAINER_PROJECT_ACCESS }
      end

      it_behaves_like 'not allowed to transfer projects' do
        let(:project_creation_level) { ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS }
      end
    end

    context 'maintainer' do
      let(:current_user) { maintainer }

      it_behaves_like 'not allowed to transfer projects' do
        let(:project_creation_level) { ::Gitlab::Access::NO_ONE_PROJECT_ACCESS }
      end

      it_behaves_like 'not allowed to transfer projects' do
        let(:project_creation_level) { ::Gitlab::Access::OWNER_PROJECT_ACCESS }
      end

      it_behaves_like 'allowed to transfer projects' do
        let(:project_creation_level) { ::Gitlab::Access::MAINTAINER_PROJECT_ACCESS }
      end

      it_behaves_like 'allowed to transfer projects' do
        let(:project_creation_level) { ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS }
      end
    end

    context 'owner' do
      let(:current_user) { owner }

      it_behaves_like 'not allowed to transfer projects' do
        let(:project_creation_level) { ::Gitlab::Access::NO_ONE_PROJECT_ACCESS }
      end

      it_behaves_like 'allowed to transfer projects' do
        let(:project_creation_level) { ::Gitlab::Access::OWNER_PROJECT_ACCESS }
      end

      it_behaves_like 'allowed to transfer projects' do
        let(:project_creation_level) { ::Gitlab::Access::MAINTAINER_PROJECT_ACCESS }
      end

      it_behaves_like 'allowed to transfer projects' do
        let(:project_creation_level) { ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS }
      end
    end
  end

  context 'create_projects' do
    context 'without visibility levels restricted' do
      where(:project_creation_level, :current_user, :create_projects_allowed?) do
        nil                                                    | lazy { planner }    | false
        nil                                                    | lazy { reporter }   | false
        nil                                                    | lazy { developer }  | true
        nil                                                    | lazy { maintainer } | true
        nil                                                    | lazy { owner }      | true
        nil                                                    | lazy { admin }      | true
        ::Gitlab::Access::NO_ONE_PROJECT_ACCESS                | lazy { planner }    | false
        ::Gitlab::Access::NO_ONE_PROJECT_ACCESS                | lazy { reporter }   | false
        ::Gitlab::Access::NO_ONE_PROJECT_ACCESS                | lazy { developer }  | false
        ::Gitlab::Access::NO_ONE_PROJECT_ACCESS                | lazy { maintainer } | false
        ::Gitlab::Access::NO_ONE_PROJECT_ACCESS                | lazy { owner }      | false
        ::Gitlab::Access::NO_ONE_PROJECT_ACCESS                | lazy { admin }      | false
        ::Gitlab::Access::OWNER_PROJECT_ACCESS                 | lazy { planner }    | false
        ::Gitlab::Access::OWNER_PROJECT_ACCESS                 | lazy { reporter }   | false
        ::Gitlab::Access::OWNER_PROJECT_ACCESS                 | lazy { developer }  | false
        ::Gitlab::Access::OWNER_PROJECT_ACCESS                 | lazy { maintainer } | false
        ::Gitlab::Access::OWNER_PROJECT_ACCESS                 | lazy { owner }      | true
        ::Gitlab::Access::OWNER_PROJECT_ACCESS                 | lazy { admin }      | true
        ::Gitlab::Access::MAINTAINER_PROJECT_ACCESS            | lazy { planner }    | false
        ::Gitlab::Access::MAINTAINER_PROJECT_ACCESS            | lazy { reporter }   | false
        ::Gitlab::Access::MAINTAINER_PROJECT_ACCESS            | lazy { developer }  | false
        ::Gitlab::Access::MAINTAINER_PROJECT_ACCESS            | lazy { maintainer } | true
        ::Gitlab::Access::MAINTAINER_PROJECT_ACCESS            | lazy { owner }      | true
        ::Gitlab::Access::MAINTAINER_PROJECT_ACCESS            | lazy { admin }      | true
        ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS  | lazy { planner }    | false
        ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS  | lazy { reporter }   | false
        ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS  | lazy { developer }  | true
        ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS  | lazy { maintainer } | true
        ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS  | lazy { owner }      | true
        ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS  | lazy { admin }      | true
        ::Gitlab::Access::ADMINISTRATOR_PROJECT_ACCESS         | lazy { planner }    | false
        ::Gitlab::Access::ADMINISTRATOR_PROJECT_ACCESS         | lazy { reporter }   | false
        ::Gitlab::Access::ADMINISTRATOR_PROJECT_ACCESS         | lazy { developer }  | false
        ::Gitlab::Access::ADMINISTRATOR_PROJECT_ACCESS         | lazy { maintainer } | false
        ::Gitlab::Access::ADMINISTRATOR_PROJECT_ACCESS         | lazy { owner }      | false
        ::Gitlab::Access::ADMINISTRATOR_PROJECT_ACCESS         | lazy { admin }      | true
      end

      with_them do
        before do
          group.update!(project_creation_level: project_creation_level)
          enable_admin_mode!(current_user) if current_user.admin?
        end

        it { is_expected.to(create_projects_allowed? ? be_allowed(:create_projects) : be_disallowed(:create_projects)) }
      end
    end

    context 'with visibility levels restricted by the administrator' do
      let_it_be(:public) { Gitlab::VisibilityLevel::PUBLIC }
      let_it_be(:internal) { Gitlab::VisibilityLevel::INTERNAL }
      let_it_be(:private) { Gitlab::VisibilityLevel::PRIVATE }
      let_it_be(:policy) { :create_projects }

      where(:restricted_visibility_levels, :group_visibility, :can_create_project?, :can_create_subgroups?) do
        []                                            | ref(:public)   | true  | true
        []                                            | ref(:internal) | true  | true
        []                                            | ref(:private)  | true  | true
        [ref(:public)]                                | ref(:public)   | true  | true
        [ref(:public)]                                | ref(:internal) | true  | true
        [ref(:public)]                                | ref(:private)  | true  | true
        [ref(:internal)]                              | ref(:public)   | true  | true
        [ref(:internal)]                              | ref(:internal) | true  | true
        [ref(:internal)]                              | ref(:private)  | true  | true
        [ref(:private)]                               | ref(:public)   | true  | true
        [ref(:private)]                               | ref(:internal) | true  | true
        [ref(:private)]                               | ref(:private)  | false | false
        [ref(:public), ref(:internal)]                | ref(:public)   | true  | true
        [ref(:public), ref(:internal)]                | ref(:internal) | true  | true
        [ref(:public), ref(:internal)]                | ref(:private)  | true  | true
        [ref(:public), ref(:private)]                 | ref(:public)   | true  | true
        [ref(:public), ref(:private)]                 | ref(:internal) | true  | true
        [ref(:public), ref(:private)]                 | ref(:private)  | false | false
        [ref(:private), ref(:internal)]               | ref(:public)   | true  | true
        [ref(:private), ref(:internal)]               | ref(:internal) | false | false
        [ref(:private), ref(:internal)]               | ref(:private)  | false | false
        [ref(:public), ref(:internal), ref(:private)] | ref(:public)   | false | false
        [ref(:public), ref(:internal), ref(:private)] | ref(:internal) | false | false
        [ref(:public), ref(:internal), ref(:private)] | ref(:private)  | false | false
      end

      with_them do
        before do
          group.update!(visibility_level: group_visibility)
          stub_application_setting(restricted_visibility_levels: restricted_visibility_levels)
        end

        context 'with non-admin user' do
          let(:current_user) { owner }

          it { is_expected.to(can_create_subgroups? ? be_allowed(:create_subgroup) : be_disallowed(:create_subgroup)) }
          it { is_expected.to(can_create_project? ? be_allowed(policy) : be_disallowed(policy)) }
        end

        context 'with admin user', :enable_admin_mode do
          let(:current_user) { admin }

          it { is_expected.to be_allowed(policy) }
        end
      end
    end
  end

  context 'import_projects' do
    before do
      group.update!(project_creation_level: project_creation_level)
    end

    context 'when group has no project creation level set' do
      let(:project_creation_level) { nil }

      context 'planner' do
        let(:current_user) { planner }

        it { is_expected.to be_disallowed(:import_projects) }
      end

      context 'reporter' do
        let(:current_user) { reporter }

        it { is_expected.to be_disallowed(:import_projects) }
      end

      context 'developer' do
        let(:current_user) { developer }

        it { is_expected.to be_disallowed(:import_projects) }
      end

      context 'maintainer' do
        let(:current_user) { maintainer }

        it { is_expected.to be_allowed(:import_projects) }
      end

      context 'owner' do
        let(:current_user) { owner }

        it { is_expected.to be_allowed(:import_projects) }
      end
    end

    context 'when group has project creation level set to no one' do
      let(:project_creation_level) { ::Gitlab::Access::NO_ONE_PROJECT_ACCESS }

      context 'planner' do
        let(:current_user) { planner }

        it { is_expected.to be_disallowed(:import_projects) }
      end

      context 'reporter' do
        let(:current_user) { reporter }

        it { is_expected.to be_disallowed(:import_projects) }
      end

      context 'developer' do
        let(:current_user) { developer }

        it { is_expected.to be_disallowed(:import_projects) }
      end

      context 'maintainer' do
        let(:current_user) { maintainer }

        it { is_expected.to be_disallowed(:import_projects) }
      end

      context 'owner' do
        let(:current_user) { owner }

        it { is_expected.to be_disallowed(:import_projects) }
      end
    end

    context 'when group has project creation level set to owner' do
      let(:project_creation_level) { ::Gitlab::Access::OWNER_PROJECT_ACCESS }

      context 'planner' do
        let(:current_user) { planner }

        it { is_expected.to be_disallowed(:import_projects) }
      end

      context 'reporter' do
        let(:current_user) { reporter }

        it { is_expected.to be_disallowed(:import_projects) }
      end

      context 'developer' do
        let(:current_user) { developer }

        it { is_expected.to be_disallowed(:import_projects) }
      end

      context 'maintainer' do
        let(:current_user) { maintainer }

        it { is_expected.to be_allowed(:import_projects) }
      end

      context 'owner' do
        let(:current_user) { owner }

        it { is_expected.to be_allowed(:import_projects) }
      end
    end

    context 'when group has project creation level set to maintainer' do
      let(:project_creation_level) { ::Gitlab::Access::MAINTAINER_PROJECT_ACCESS }

      context 'planner' do
        let(:current_user) { planner }

        it { is_expected.to be_disallowed(:import_projects) }
      end

      context 'reporter' do
        let(:current_user) { reporter }

        it { is_expected.to be_disallowed(:import_projects) }
      end

      context 'developer' do
        let(:current_user) { developer }

        it { is_expected.to be_disallowed(:import_projects) }
      end

      context 'maintainer' do
        let(:current_user) { maintainer }

        it { is_expected.to be_allowed(:import_projects) }
      end

      context 'owner' do
        let(:current_user) { owner }

        it { is_expected.to be_allowed(:import_projects) }
      end
    end

    context 'when group has project creation level set to developers + maintainer' do
      let(:project_creation_level) { ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS }

      context 'planner' do
        let(:current_user) { planner }

        it { is_expected.to be_disallowed(:import_projects) }
      end

      context 'reporter' do
        let(:current_user) { reporter }

        it { is_expected.to be_disallowed(:import_projects) }
      end

      context 'developer' do
        let(:current_user) { developer }

        it { is_expected.to be_disallowed(:import_projects) }
      end

      context 'maintainer' do
        let(:current_user) { maintainer }

        it { is_expected.to be_allowed(:import_projects) }
      end

      context 'owner' do
        let(:current_user) { owner }

        it { is_expected.to be_allowed(:import_projects) }
      end
    end
  end

  context 'create_subgroup' do
    context 'when group has subgroup creation level set to owner' do
      before do
        group.update!(subgroup_creation_level: ::Gitlab::Access::OWNER_SUBGROUP_ACCESS)
      end

      context 'planner' do
        let(:current_user) { planner }

        it { is_expected.to be_disallowed(:create_subgroup) }
      end

      context 'reporter' do
        let(:current_user) { reporter }

        it { is_expected.to be_disallowed(:create_subgroup) }
      end

      context 'developer' do
        let(:current_user) { developer }

        it { is_expected.to be_disallowed(:create_subgroup) }
      end

      context 'maintainer' do
        let(:current_user) { maintainer }

        it { is_expected.to be_disallowed(:create_subgroup) }
      end

      context 'owner' do
        let(:current_user) { owner }

        it { is_expected.to be_allowed(:create_subgroup) }
      end
    end

    context 'when group has subgroup creation level set to maintainer' do
      before do
        group.update!(subgroup_creation_level: ::Gitlab::Access::MAINTAINER_SUBGROUP_ACCESS)
      end

      context 'planner' do
        let(:current_user) { planner }

        it { is_expected.to be_disallowed(:create_subgroup) }
      end

      context 'reporter' do
        let(:current_user) { reporter }

        it { is_expected.to be_disallowed(:create_subgroup) }
      end

      context 'developer' do
        let(:current_user) { developer }

        it { is_expected.to be_disallowed(:create_subgroup) }
      end

      context 'maintainer' do
        let(:current_user) { maintainer }

        it { is_expected.to be_allowed(:create_subgroup) }
      end

      context 'owner' do
        let(:current_user) { owner }

        it { is_expected.to be_allowed(:create_subgroup) }
      end
    end
  end

  it_behaves_like 'clusterable policies' do
    let(:clusterable) { create(:group) }
    let(:cluster) do
      create(:cluster, :provided_by_gcp, :group, groups: [clusterable])
    end
  end

  describe 'update_max_artifacts_size' do
    let(:group) { create(:group, :public) }

    context 'when no user' do
      let(:current_user) { nil }

      it { expect_disallowed(:update_max_artifacts_size) }
    end

    context 'admin' do
      let(:current_user) { admin }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { expect_allowed(:update_max_artifacts_size) }
      end

      context 'when admin mode is enabled' do
        it { expect_disallowed(:update_max_artifacts_size) }
      end
    end

    %w[guest planner reporter developer maintainer owner].each do |role|
      context role do
        let(:current_user) { send(role) }

        it { expect_disallowed(:update_max_artifacts_size) }
      end
    end
  end

  describe 'design activity' do
    let_it_be(:group) { create(:group, :public) }

    let(:current_user) { nil }

    subject { described_class.new(current_user, group) }

    context 'when design management is not available' do
      it { is_expected.not_to be_allowed(:read_design_activity) }

      context 'even when there are projects in the group' do
        before do
          create_list(:project_group_link, 2, group: group)
        end

        it { is_expected.not_to be_allowed(:read_design_activity) }
      end
    end

    context 'when design management is available globally' do
      include DesignManagementTestHelpers

      before do
        enable_design_management
      end

      context 'the group has no projects' do
        it { is_expected.not_to be_allowed(:read_design_activity) }
      end

      context 'the group has a project' do
        let(:project) { create(:project, :public) }

        before do
          create(:project_group_link, project: project, group: group)
        end

        it { is_expected.to be_allowed(:read_design_activity) }

        context 'which does not have design management enabled' do
          before do
            project.update!(lfs_enabled: false)
          end

          it { is_expected.not_to be_allowed(:read_design_activity) }

          context 'but another project does' do
            before do
              create(:project_group_link, project: create(:project, :public), group: group)
            end

            it { is_expected.to be_allowed(:read_design_activity) }
          end
        end
      end
    end
  end

  describe 'create_jira_connect_subscription' do
    context 'admin' do
      let(:current_user) { admin }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:create_jira_connect_subscription) }
      end

      context 'when admin mode is disabled' do
        it { is_expected.to be_disallowed(:create_jira_connect_subscription) }
      end
    end

    context 'with owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:create_jira_connect_subscription) }
    end

    context 'with maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_allowed(:create_jira_connect_subscription) }
    end

    context 'with reporter' do
      let(:current_user) { reporter }

      it { is_expected.to be_disallowed(:create_jira_connect_subscription) }
    end

    context 'with planner' do
      let(:current_user) { planner }

      it { is_expected.to be_disallowed(:create_jira_connect_subscription) }
    end

    context 'with guest' do
      let(:current_user) { guest }

      it { is_expected.to be_disallowed(:create_jira_connect_subscription) }
    end

    context 'with non member' do
      let(:current_user) { create(:user) }

      it { is_expected.to be_disallowed(:create_jira_connect_subscription) }
    end

    context 'with anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(:create_jira_connect_subscription) }
    end
  end

  describe 'read_package' do
    context 'admin' do
      let(:current_user) { admin }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:read_package) }
      end

      context 'when admin mode is disabled' do
        it { is_expected.to be_disallowed(:read_package) }
      end
    end

    context 'with owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:read_package) }
    end

    context 'with maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_allowed(:read_package) }
    end

    context 'with reporter' do
      let(:current_user) { reporter }

      it { is_expected.to be_allowed(:read_package) }
    end

    context 'with planner' do
      let(:current_user) { planner }

      it { is_expected.to be_allowed(:read_package) }

      context 'when allow_guest_plus_roles_to_pull_packages is disabled' do
        before do
          stub_feature_flags(allow_guest_plus_roles_to_pull_packages: false)
        end

        it { is_expected.to be_disallowed(:read_package) }
      end
    end

    context 'with guest' do
      let(:current_user) { guest }

      it { is_expected.to be_allowed(:read_package) }

      context 'when allow_guest_plus_roles_to_pull_packages is disabled' do
        before do
          stub_feature_flags(allow_guest_plus_roles_to_pull_packages: false)
        end

        it { is_expected.to be_disallowed(:read_package) }
      end
    end

    context 'with non member' do
      let(:current_user) { create(:user) }

      it { is_expected.to be_disallowed(:read_package) }
    end

    context 'with anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(:read_package) }
    end
  end

  describe 'dependency proxy' do
    shared_examples 'disallows all dependency proxy access' do
      it { is_expected.to be_disallowed(:read_dependency_proxy) }
      it { is_expected.to be_disallowed(:admin_dependency_proxy) }
    end

    shared_examples 'allows dependency proxy read access but not admin' do
      it { is_expected.to be_allowed(:read_dependency_proxy) }
      it { is_expected.to be_disallowed(:admin_dependency_proxy) }
    end

    context 'feature disabled' do
      let(:current_user) { owner }

      before do
        stub_config(dependency_proxy: { enabled: false })
      end

      it_behaves_like 'disallows all dependency proxy access'
    end

    context 'feature enabled' do
      before do
        stub_config(dependency_proxy: { enabled: true }, registry: { enabled: true })
      end

      context 'human user' do
        context 'reporter' do
          let(:current_user) { reporter }

          it_behaves_like 'allows dependency proxy read access but not admin'
        end

        context 'developer' do
          let(:current_user) { developer }

          it_behaves_like 'allows dependency proxy read access but not admin'
        end

        context 'maintainer' do
          let(:current_user) { maintainer }

          it_behaves_like 'allows dependency proxy read access but not admin'
        end

        context 'owner' do
          let(:current_user) { owner }

          it { is_expected.to be_allowed(:read_dependency_proxy) }
          it { is_expected.to be_allowed(:admin_dependency_proxy) }
        end
      end

      context 'placeholder user' do
        let_it_be(:placeholder_user) { create(:user, user_type: :placeholder, developer_of: group) }

        subject { described_class.new(placeholder_user, group) }

        it_behaves_like 'disallows all dependency proxy access'
      end

      context 'import user' do
        let_it_be(:import_user) { create(:user, user_type: :import_user, developer_of: group) }

        subject { described_class.new(import_user, group) }

        it_behaves_like 'disallows all dependency proxy access'
      end

      context 'all other user types' do
        User::USER_TYPES.except(:human, :project_bot, :placeholder, :import_user).each_value do |user_type|
          context "with user_type #{user_type}" do
            before do
              current_user.update!(user_type: user_type)
            end

            context 'when the user has sufficient access' do
              let(:current_user) { guest }

              it_behaves_like 'allows dependency proxy read access but not admin'
            end

            context 'when the user does not have sufficient access' do
              let(:current_user) { non_group_member }

              it_behaves_like 'disallows all dependency proxy access'
            end
          end
        end
      end
    end
  end

  context 'package registry' do
    context 'deploy token user' do
      let!(:group_deploy_token) do
        create(:group_deploy_token, group: group, deploy_token: deploy_token)
      end

      subject { described_class.new(deploy_token, group) }

      context 'with read_package_registry scope' do
        let(:deploy_token) { create(:deploy_token, :group, read_package_registry: true) }

        it { is_expected.to be_allowed(:read_package) }
        it { is_expected.to be_allowed(:read_group) }
        it { is_expected.to be_disallowed(:create_package) }
      end

      context 'with write_package_registry scope' do
        let(:deploy_token) { create(:deploy_token, :group, write_package_registry: true) }

        it { is_expected.to be_allowed(:create_package) }
        it { is_expected.to be_allowed(:read_package) }
        it { is_expected.to be_allowed(:read_group) }
        it { is_expected.to be_disallowed(:destroy_package) }
      end
    end
  end

  it_behaves_like 'Self-managed Core resource access tokens'

  context 'support bot' do
    let_it_be_with_refind(:group) { create(:group, :private) }
    let_it_be(:current_user) { Users::Internal.support_bot }

    before do
      allow(::ServiceDesk).to receive(:supported?).and_return(true)
    end

    it { expect_disallowed(:read_label) }

    context 'when group hierarchy has a project with service desk enabled' do
      let_it_be(:subgroup) { create(:group, :private, parent: group) }
      let_it_be(:project) { create(:project, group: subgroup, service_desk_enabled: true) }

      it { expect_allowed(:read_label) }
      it { expect(described_class.new(current_user, subgroup)).to be_allowed(:read_label) }
    end
  end

  context "project bots" do
    let(:project_bot) { create(:user, :project_bot) }
    let(:user) { create(:user) }

    context "project_bot_access" do
      context "when regular user and part of the group" do
        let(:current_user) { user }

        before do
          group.add_developer(user)
        end

        it { is_expected.not_to be_allowed(:project_bot_access) }
      end

      context "when project bot and not part of the project" do
        let(:current_user) { project_bot }

        it { is_expected.not_to be_allowed(:project_bot_access) }
      end

      context "when project bot and part of the project" do
        let(:current_user) { project_bot }

        before do
          group.add_developer(project_bot)
        end

        it { is_expected.to be_allowed(:project_bot_access) }
      end
    end

    context 'with resource access tokens' do
      let(:current_user) { project_bot }

      before do
        group.add_maintainer(project_bot)
      end

      it { is_expected.not_to be_allowed(:create_resource_access_tokens) }
    end
  end

  describe 'update_runners_registration_token' do
    let(:allow_runner_registration_token) { true }

    before do
      stub_application_setting(allow_runner_registration_token: allow_runner_registration_token)
    end

    context 'admin' do
      let(:current_user) { admin }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:update_runners_registration_token) }

        context 'with registration tokens disabled' do
          let(:allow_runner_registration_token) { false }

          it { is_expected.to be_disallowed(:update_runners_registration_token) }
        end
      end

      context 'when admin mode is disabled' do
        it { is_expected.to be_disallowed(:update_runners_registration_token) }
      end
    end

    context 'with owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:update_runners_registration_token) }

      context 'with registration tokens disabled' do
        let(:allow_runner_registration_token) { false }

        it { is_expected.to be_disallowed(:update_runners_registration_token) }
      end
    end

    context 'with maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_disallowed(:update_runners_registration_token) }
    end

    context 'with reporter' do
      let(:current_user) { reporter }

      it { is_expected.to be_disallowed(:update_runners_registration_token) }
    end

    context 'with planner' do
      let(:current_user) { planner }

      it { is_expected.to be_disallowed(:update_runners_registration_token) }
    end

    context 'with guest' do
      let(:current_user) { guest }

      it { is_expected.to be_disallowed(:update_runners_registration_token) }
    end

    context 'with non member' do
      let(:current_user) { create(:user) }

      it { is_expected.to be_disallowed(:update_runners_registration_token) }
    end

    context 'with anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(:update_runners_registration_token) }
    end
  end

  describe 'register_group_runners' do
    let(:allow_runner_registration_token) { true }

    before do
      stub_application_setting(allow_runner_registration_token: allow_runner_registration_token)
    end

    context 'admin' do
      let(:current_user) { admin }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:register_group_runners) }

        context 'with registration tokens disabled' do
          let(:allow_runner_registration_token) { false }

          it { is_expected.to be_disallowed(:register_group_runners) }
        end

        context 'with specific group runner registration disabled' do
          before do
            group.runner_registration_enabled = false
          end

          it { is_expected.to be_allowed(:register_group_runners) }
        end

        context 'with group runner registration disabled' do
          before do
            stub_application_setting(valid_runner_registrars: ['project'])
          end

          it { is_expected.to be_allowed(:register_group_runners) }

          context 'with registration tokens disabled' do
            let(:allow_runner_registration_token) { false }

            it { is_expected.to be_disallowed(:register_group_runners) }
          end

          context 'with specific group runner registration disabled' do
            before do
              group.runner_registration_enabled = false
            end

            it { is_expected.to be_allowed(:register_group_runners) }
          end

          context 'with specific group runner registration token disallowed' do
            before do
              group.allow_runner_registration_token = false
            end

            it { is_expected.to be_disallowed(:register_group_runners) }
          end
        end
      end

      context 'when admin mode is disabled' do
        it { is_expected.to be_disallowed(:register_group_runners) }
      end
    end

    context 'with owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:register_group_runners) }

      context 'with registration tokens disabled' do
        let(:allow_runner_registration_token) { false }

        it { is_expected.to be_disallowed(:register_group_runners) }
      end

      context 'with group runner registration disabled' do
        before do
          stub_application_setting(valid_runner_registrars: ['project'])
        end

        it { is_expected.to be_disallowed(:register_group_runners) }
      end

      context 'with specific group runner registration disabled' do
        before do
          group.runner_registration_enabled = false
        end

        it { is_expected.to be_disallowed(:register_group_runners) }
      end

      context 'with specific group runner registration token disallowed' do
        before do
          group.allow_runner_registration_token = false
        end

        it { is_expected.to be_disallowed(:register_group_runners) }
      end
    end

    context 'with maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_disallowed(:register_group_runners) }
    end

    context 'with reporter' do
      let(:current_user) { reporter }

      it { is_expected.to be_disallowed(:register_group_runners) }
    end

    context 'with planner' do
      let(:current_user) { planner }

      it { is_expected.to be_disallowed(:register_group_runners) }
    end

    context 'with guest' do
      let(:current_user) { guest }

      it { is_expected.to be_disallowed(:register_group_runners) }
    end

    context 'with non member' do
      let(:current_user) { create(:user) }

      it { is_expected.to be_disallowed(:register_group_runners) }
    end

    context 'with anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(:register_group_runners) }
    end
  end

  describe 'create_runner' do
    shared_examples 'disallowed when group runner registration disabled' do
      context 'with group runner registration disabled' do
        before do
          stub_application_setting(valid_runner_registrars: ['project'])
          group.runner_registration_enabled = runner_registration_enabled
        end

        context 'with specific group runner registration enabled' do
          let(:runner_registration_enabled) { true }

          it { is_expected.to be_disallowed(:create_runner) }
        end

        context 'with specific group runner registration disabled' do
          let(:runner_registration_enabled) { false }

          it { is_expected.to be_disallowed(:create_runner) }
        end
      end
    end

    context 'admin' do
      let(:current_user) { admin }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:create_runner) }

        context 'with specific group runner registration disabled' do
          before do
            group.runner_registration_enabled = false
          end

          it { is_expected.to be_allowed(:create_runner) }
        end

        context 'with group runner registration disabled' do
          before do
            stub_application_setting(valid_runner_registrars: ['project'])
            group.runner_registration_enabled = runner_registration_enabled
          end

          context 'with specific group runner registration enabled' do
            let(:runner_registration_enabled) { true }

            it { is_expected.to be_allowed(:create_runner) }
          end

          context 'with specific group runner registration disabled' do
            let(:runner_registration_enabled) { false }

            it { is_expected.to be_allowed(:create_runner) }
          end
        end
      end

      context 'when admin mode is disabled' do
        it { is_expected.to be_disallowed(:create_runner) }
      end
    end

    context 'with owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:create_runner) }

      it_behaves_like 'disallowed when group runner registration disabled'
    end

    context 'with maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_disallowed(:create_runner) }
    end

    context 'with reporter' do
      let(:current_user) { reporter }

      it { is_expected.to be_disallowed(:create_runner) }
    end

    context 'with planner' do
      let(:current_user) { planner }

      it { is_expected.to be_disallowed(:create_runner) }
    end

    context 'with guest' do
      let(:current_user) { guest }

      it { is_expected.to be_disallowed(:create_runner) }
    end

    context 'with developer' do
      let(:current_user) { developer }

      it { is_expected.to be_disallowed(:create_runner) }
    end

    context 'with anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(:create_runner) }
    end
  end

  describe 'read_group_all_available_runners' do
    context 'admin' do
      let(:current_user) { admin }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:read_group_all_available_runners) }
      end

      context 'when admin mode is disabled' do
        it { is_expected.to be_disallowed(:read_group_all_available_runners) }
      end
    end

    context 'with owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:read_group_all_available_runners) }
    end

    context 'with maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_allowed(:read_group_all_available_runners) }
    end

    context 'with developer' do
      let(:current_user) { developer }

      it { is_expected.to be_allowed(:read_group_all_available_runners) }
    end

    context 'with reporter' do
      let(:current_user) { reporter }

      it { is_expected.to be_disallowed(:read_group_all_available_runners) }
    end

    context 'with planner' do
      let(:current_user) { planner }

      it { is_expected.to be_disallowed(:read_group_all_available_runners) }
    end

    context 'with guest' do
      let(:current_user) { guest }

      it { is_expected.to be_disallowed(:read_group_all_available_runners) }
    end

    context 'with non member' do
      let(:current_user) { create(:user) }

      it { is_expected.to be_disallowed(:read_group_all_available_runners) }
    end

    context 'with anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(:read_group_all_available_runners) }
    end
  end

  describe 'change_prevent_sharing_groups_outside_hierarchy' do
    context 'with owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:change_prevent_sharing_groups_outside_hierarchy) }
    end

    context 'with non-owner roles' do
      where(role: %w[admin maintainer reporter developer guest])

      with_them do
        let(:current_user) { public_send role }

        it { is_expected.to be_disallowed(:change_prevent_sharing_groups_outside_hierarchy) }
      end
    end
  end

  context 'when crm_enabled is false' do
    let(:current_user) { owner }

    before do
      create(:crm_settings, group: group, enabled: false)
    end

    it { is_expected.to be_disallowed(:read_crm_contact) }
    it { is_expected.to be_disallowed(:read_crm_organization) }
    it { is_expected.to be_disallowed(:admin_crm_contact) }
    it { is_expected.to be_disallowed(:admin_crm_organization) }
  end

  it_behaves_like 'checks timelog categories permissions' do
    let(:group) { create(:group) }
    let(:namespace) { group }
    let(:users_container) { group }

    subject { described_class.new(current_user, group) }
  end

  describe 'read_usage_quotas policy' do
    context 'reading usage quotas' do
      let(:policy) { :read_usage_quotas }

      where(:role, :admin_mode, :allowed) do
        :owner      | nil   | true
        :admin      | true  | true
        :admin      | false | false
        :maintainer | nil   | false
        :developer  | nil   | false
        :reporter   | nil   | false
        :planner    | nil   | false
        :guest      | nil   | false
      end

      with_them do
        let(:current_user) { public_send(role) }

        before do
          enable_admin_mode!(current_user) if admin_mode
        end

        it { is_expected.to(allowed ? be_allowed(policy) : be_disallowed(policy)) }
      end
    end
  end

  describe 'achievements' do
    let(:current_user) { owner }

    it { is_expected.to be_allowed(:read_achievement) }
    it { is_expected.to be_allowed(:admin_achievement) }
    it { is_expected.to be_allowed(:award_achievement) }
    it { is_expected.to be_allowed(:destroy_user_achievement) }

    context 'with feature flag disabled' do
      before do
        stub_feature_flags(achievements: false)
      end

      it { is_expected.to be_disallowed(:read_achievement) }
      it { is_expected.to be_disallowed(:admin_achievement) }
      it { is_expected.to be_disallowed(:award_achievement) }
      it { is_expected.to be_disallowed(:destroy_user_achievement) }
    end

    context 'when current user is not a group member' do
      let(:current_user) { non_group_member }

      it { is_expected.to be_disallowed(:read_achievement) }

      context 'when the group is public' do
        let_it_be(:group) { create(:group, :public) }

        it { is_expected.to be_allowed(:read_achievement) }
      end
    end

    context 'when current user is not an owner' do
      let(:current_user) { maintainer }

      it { is_expected.to be_disallowed(:destroy_user_achievement) }
    end
  end

  describe 'admin_package ability' do
    context 'with maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_disallowed(:admin_package) }
    end

    context 'with owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:admin_package) }
    end
  end
end
