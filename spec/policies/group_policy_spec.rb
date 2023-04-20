# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupPolicy, feature_category: :system_access do
  include AdminModeHelper
  include_context 'GroupPolicy context'
  using RSpec::Parameterized::TableSyntax

  context 'public group with no user' do
    let(:group) { create(:group, :public, :crm_enabled) }
    let(:current_user) { nil }

    specify do
      expect_allowed(*public_permissions)
      expect_disallowed(:upload_file)
      expect_disallowed(*reporter_permissions)
      expect_disallowed(*developer_permissions)
      expect_disallowed(*maintainer_permissions)
      expect_disallowed(*owner_permissions)
      expect_disallowed(:read_namespace)
    end
  end

  context 'public group with user who is not a member' do
    let(:group) { create(:group, :public, :crm_enabled) }
    let(:current_user) { create(:user) }

    specify do
      expect_allowed(*public_permissions)
      expect_disallowed(:upload_file)
      expect_disallowed(*reporter_permissions)
      expect_disallowed(*developer_permissions)
      expect_disallowed(*maintainer_permissions)
      expect_disallowed(*owner_permissions)
      expect_disallowed(:read_namespace)
    end
  end

  context 'private group that has been invited to a public project and with no user' do
    let(:project) { create(:project, :public, group: create(:group, :crm_enabled)) }
    let(:current_user) { nil }

    before do
      create(:project_group_link, project: project, group: group)
    end

    specify do
      expect_disallowed(*public_permissions)
      expect_disallowed(*reporter_permissions)
      expect_disallowed(*owner_permissions)
    end
  end

  context 'private group that has been invited to a public project and with a foreign user' do
    let(:project) { create(:project, :public, group: create(:group, :crm_enabled)) }
    let(:current_user) { create(:user) }

    before do
      create(:project_group_link, project: project, group: group)
    end

    specify do
      expect_disallowed(*public_permissions)
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
      let(:subgroup) { create(:group, :private, :crm_enabled, parent: group) }
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
      expect_disallowed(*reporter_permissions)
      expect_disallowed(*developer_permissions)
      expect_disallowed(*maintainer_permissions)
      expect_disallowed(*owner_permissions)
    end

    it_behaves_like 'deploy token does not get confused with user' do
      let(:user_id) { guest.id }
    end
  end

  context 'reporter' do
    let(:current_user) { reporter }

    specify do
      expect_allowed(*public_permissions)
      expect_allowed(*guest_permissions)
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

      it 'allows every maintainer permission plus creating subgroups' do
        create_subgroup_permission = [:create_subgroup]
        updated_maintainer_permissions =
          maintainer_permissions + create_subgroup_permission
        updated_owner_permissions =
          owner_permissions - create_subgroup_permission

        expect_allowed(*public_permissions)
        expect_allowed(*guest_permissions)
        expect_allowed(*reporter_permissions)
        expect_allowed(*developer_permissions)
        expect_allowed(*updated_maintainer_permissions)
        expect_disallowed(*updated_owner_permissions)
      end
    end

    context 'with subgroup_creation_level set to owner' do
      it 'allows every maintainer permission' do
        expect_allowed(*public_permissions)
        expect_allowed(*guest_permissions)
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
      expect_disallowed(*reporter_permissions)
      expect_disallowed(*developer_permissions)
      expect_disallowed(*maintainer_permissions)
      expect_disallowed(*owner_permissions)
    end

    context 'with admin mode', :enable_admin_mode do
      specify do
        expect_allowed(*public_permissions)
        expect_allowed(*guest_permissions)
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

  context 'migration bot' do
    let_it_be(:migration_bot) { User.migration_bot }
    let_it_be(:current_user) { migration_bot }

    it :aggregate_failures do
      expect_allowed(:read_resource_access_tokens, :destroy_resource_access_tokens)
      expect_disallowed(*guest_permissions)
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
        expect_disallowed(*reporter_permissions)
        expect_disallowed(*developer_permissions)
        expect_disallowed(*maintainer_permissions)
        expect_disallowed(*owner_permissions)
      end
    end
  end

  describe 'private nested group use the highest access level from the group and inherited permissions' do
    let_it_be(:nested_group) do
      create(:group, :private, :owner_subgroup_creation_only, :crm_enabled, parent: group)
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
        expect_disallowed(*reporter_permissions)
        expect_disallowed(*developer_permissions)
        expect_disallowed(*maintainer_permissions)
        expect_disallowed(*owner_permissions)
      end
    end

    context 'reporter' do
      let(:current_user) { reporter }

      specify do
        expect_allowed(*public_permissions)
        expect_allowed(*guest_permissions)
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
        expect_allowed(*reporter_permissions)
        expect_allowed(*developer_permissions)
        expect_allowed(*maintainer_permissions)
        expect_disallowed(*owner_permissions)
      end
    end

    context 'owner' do
      let(:current_user) { owner }

      specify do
        expect_allowed(*public_permissions)
        expect_allowed(*guest_permissions)
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
        let(:group) { create(:group, :crm_enabled, share_with_group_lock: true, parent: parent) }

        before do
          group.add_owner(owner)
        end

        context 'when the parent group share_with_group_lock is enabled' do
          context 'when the group has a grandparent' do
            let(:parent) { create(:group, :crm_enabled, share_with_group_lock: true, parent: grandparent) }

            context 'when the grandparent share_with_group_lock is enabled' do
              let(:grandparent) { create(:group, :crm_enabled, share_with_group_lock: true) }

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
              let(:grandparent) { create(:group, :crm_enabled) }

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
            let(:parent) { create(:group, :crm_enabled, share_with_group_lock: true) }

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
          let(:parent) { create(:group, :crm_enabled) }

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
        let(:project_creation_level) { ::Gitlab::Access::MAINTAINER_PROJECT_ACCESS }
      end

      it_behaves_like 'allowed to transfer projects' do
        let(:project_creation_level) { ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS }
      end
    end
  end

  context 'create_projects' do
    context 'when group has no project creation level set' do
      before do
        group.update!(project_creation_level: nil)
      end

      context 'reporter' do
        let(:current_user) { reporter }

        it { is_expected.to be_disallowed(:create_projects) }
      end

      context 'developer' do
        let(:current_user) { developer }

        it { is_expected.to be_allowed(:create_projects) }
      end

      context 'maintainer' do
        let(:current_user) { maintainer }

        it { is_expected.to be_allowed(:create_projects) }
      end

      context 'owner' do
        let(:current_user) { owner }

        it { is_expected.to be_allowed(:create_projects) }
      end
    end

    context 'when group has project creation level set to no one' do
      before do
        group.update!(project_creation_level: ::Gitlab::Access::NO_ONE_PROJECT_ACCESS)
      end

      context 'reporter' do
        let(:current_user) { reporter }

        it { is_expected.to be_disallowed(:create_projects) }
      end

      context 'developer' do
        let(:current_user) { developer }

        it { is_expected.to be_disallowed(:create_projects) }
      end

      context 'maintainer' do
        let(:current_user) { maintainer }

        it { is_expected.to be_disallowed(:create_projects) }
      end

      context 'owner' do
        let(:current_user) { owner }

        it { is_expected.to be_disallowed(:create_projects) }
      end
    end

    context 'when group has project creation level set to maintainer only' do
      before do
        group.update!(project_creation_level: ::Gitlab::Access::MAINTAINER_PROJECT_ACCESS)
      end

      context 'reporter' do
        let(:current_user) { reporter }

        it { is_expected.to be_disallowed(:create_projects) }
      end

      context 'developer' do
        let(:current_user) { developer }

        it { is_expected.to be_disallowed(:create_projects) }
      end

      context 'maintainer' do
        let(:current_user) { maintainer }

        it { is_expected.to be_allowed(:create_projects) }
      end

      context 'owner' do
        let(:current_user) { owner }

        it { is_expected.to be_allowed(:create_projects) }
      end
    end

    context 'when group has project creation level set to developers + maintainer' do
      before do
        group.update!(project_creation_level: ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS)
      end

      context 'reporter' do
        let(:current_user) { reporter }

        it { is_expected.to be_disallowed(:create_projects) }
      end

      context 'developer' do
        let(:current_user) { developer }

        it { is_expected.to be_allowed(:create_projects) }
      end

      context 'maintainer' do
        let(:current_user) { maintainer }

        it { is_expected.to be_allowed(:create_projects) }
      end

      context 'owner' do
        let(:current_user) { owner }

        it { is_expected.to be_allowed(:create_projects) }
      end
    end

    context 'with visibility levels restricted by the administrator' do
      let_it_be(:public) { Gitlab::VisibilityLevel::PUBLIC }
      let_it_be(:internal) { Gitlab::VisibilityLevel::INTERNAL }
      let_it_be(:private) { Gitlab::VisibilityLevel::PRIVATE }
      let_it_be(:policy) { :create_projects }

      where(:restricted_visibility_levels, :group_visibility, :can_create_project?) do
        []                                            | ref(:public)   | true
        []                                            | ref(:internal) | true
        []                                            | ref(:private)  | true
        [ref(:public)]                                | ref(:public)   | true
        [ref(:public)]                                | ref(:internal) | true
        [ref(:public)]                                | ref(:private)  | true
        [ref(:internal)]                              | ref(:public)   | true
        [ref(:internal)]                              | ref(:internal) | true
        [ref(:internal)]                              | ref(:private)  | true
        [ref(:private)]                               | ref(:public)   | true
        [ref(:private)]                               | ref(:internal) | true
        [ref(:private)]                               | ref(:private)  | false
        [ref(:public), ref(:internal)]                | ref(:public)   | true
        [ref(:public), ref(:internal)]                | ref(:internal) | true
        [ref(:public), ref(:internal)]                | ref(:private)  | true
        [ref(:public), ref(:private)]                 | ref(:public)   | true
        [ref(:public), ref(:private)]                 | ref(:internal) | true
        [ref(:public), ref(:private)]                 | ref(:private)  | false
        [ref(:private), ref(:internal)]               | ref(:public)   | true
        [ref(:private), ref(:internal)]               | ref(:internal) | false
        [ref(:private), ref(:internal)]               | ref(:private)  | false
        [ref(:public), ref(:internal), ref(:private)] | ref(:public)   | false
        [ref(:public), ref(:internal), ref(:private)] | ref(:internal) | false
        [ref(:public), ref(:internal), ref(:private)] | ref(:private)  | false
      end

      with_them do
        before do
          group.update!(visibility_level: group_visibility)
          stub_application_setting(restricted_visibility_levels: restricted_visibility_levels)
        end

        context 'with non-admin user' do
          let(:current_user) { owner }

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

    context 'when group has project creation level set to maintainer only' do
      let(:project_creation_level) { ::Gitlab::Access::MAINTAINER_PROJECT_ACCESS }

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
    let(:clusterable) { create(:group, :crm_enabled) }
    let(:cluster) do
      create(:cluster, :provided_by_gcp, :group, groups: [clusterable])
    end
  end

  describe 'update_max_artifacts_size' do
    let(:group) { create(:group, :public, :crm_enabled) }

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

    %w[guest reporter developer maintainer owner].each do |role|
      context role do
        let(:current_user) { send(role) }

        it { expect_disallowed(:update_max_artifacts_size) }
      end
    end
  end

  describe 'design activity' do
    let_it_be(:group) { create(:group, :public, :crm_enabled) }

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

    context 'with guest' do
      let(:current_user) { guest }

      it { is_expected.to be_disallowed(:read_package) }
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

  describe 'observability' do
    let(:allowed_admin) { be_allowed(:read_observability) && be_allowed(:admin_observability) }
    let(:allowed_read) { be_allowed(:read_observability) && be_disallowed(:admin_observability) }
    let(:disallowed) { be_disallowed(:read_observability) && be_disallowed(:admin_observability) }

    # rubocop:disable Layout/LineLength
    where(:feature_enabled, :admin_matcher, :owner_matcher, :maintainer_matcher, :developer_matcher, :reporter_matcher, :guest_matcher, :non_member_matcher, :anonymous_matcher) do
      false | ref(:disallowed) | ref(:disallowed) | ref(:disallowed) | ref(:disallowed) | ref(:disallowed) | ref(:disallowed) | ref(:disallowed) | ref(:disallowed)
      true | ref(:allowed_admin) | ref(:allowed_admin) | ref(:allowed_admin) | ref(:allowed_read) | ref(:disallowed) | ref(:disallowed) | ref(:disallowed) | ref(:disallowed)
    end
    # rubocop:enable Layout/LineLength

    with_them do
      before do
        stub_feature_flags(observability_group_tab: feature_enabled)
      end

      context 'admin', :enable_admin_mode do
        let(:current_user) { admin }

        it { is_expected.to admin_matcher }
      end

      context 'owner' do
        let(:current_user) { owner }

        it { is_expected.to owner_matcher }
      end

      context 'maintainer' do
        let(:current_user) { maintainer }

        it { is_expected.to maintainer_matcher }
      end

      context 'developer' do
        let(:current_user) { developer }

        it { is_expected.to developer_matcher }
      end

      context 'reporter' do
        let(:current_user) { reporter }

        it { is_expected.to reporter_matcher }
      end

      context 'with guest' do
        let(:current_user) { guest }

        it { is_expected.to guest_matcher }
      end

      context 'with non member' do
        let(:current_user) { create(:user) }

        it { is_expected.to non_member_matcher }
      end

      context 'with anonymous' do
        let(:current_user) { nil }

        it { is_expected.to anonymous_matcher }
      end
    end
  end

  describe 'dependency proxy' do
    context 'feature disabled' do
      let(:current_user) { owner }

      it { is_expected.to be_disallowed(:read_dependency_proxy) }
      it { is_expected.to be_disallowed(:admin_dependency_proxy) }
    end

    context 'feature enabled' do
      before do
        stub_config(dependency_proxy: { enabled: true })
      end

      context 'reporter' do
        let(:current_user) { reporter }

        it { is_expected.to be_allowed(:read_dependency_proxy) }
        it { is_expected.to be_disallowed(:admin_dependency_proxy) }
      end

      context 'developer' do
        let(:current_user) { developer }

        it { is_expected.to be_allowed(:read_dependency_proxy) }
        it { is_expected.to be_disallowed(:admin_dependency_proxy) }
      end

      context 'maintainer' do
        let(:current_user) { maintainer }

        it { is_expected.to be_allowed(:read_dependency_proxy) }
        it { is_expected.to be_allowed(:admin_dependency_proxy) }
      end
    end
  end

  context 'deploy token access' do
    let!(:group_deploy_token) do
      create(:group_deploy_token, group: group, deploy_token: deploy_token)
    end

    subject { described_class.new(deploy_token, group) }

    context 'a deploy token with read_package_registry scope' do
      let(:deploy_token) { create(:deploy_token, :group, read_package_registry: true) }

      it { is_expected.to be_allowed(:read_package) }
      it { is_expected.to be_allowed(:read_group) }
      it { is_expected.to be_disallowed(:create_package) }
    end

    context 'a deploy token with write_package_registry scope' do
      let(:deploy_token) { create(:deploy_token, :group, write_package_registry: true) }

      it { is_expected.to be_allowed(:create_package) }
      it { is_expected.to be_allowed(:read_package) }
      it { is_expected.to be_allowed(:read_group) }
      it { is_expected.to be_disallowed(:destroy_package) }
    end

    context 'a deploy token with dependency proxy scopes' do
      let_it_be(:deploy_token) { create(:deploy_token, :group, :dependency_proxy_scopes) }

      before do
        stub_config(dependency_proxy: { enabled: true })
      end

      it { is_expected.to be_allowed(:read_dependency_proxy) }
      it { is_expected.to be_disallowed(:admin_dependency_proxy) }
    end
  end

  it_behaves_like 'Self-managed Core resource access tokens'

  context 'support bot' do
    let_it_be_with_refind(:group) { create(:group, :private, :crm_enabled) }
    let_it_be(:current_user) { User.support_bot }

    before do
      allow(Gitlab::ServiceDesk).to receive(:supported?).and_return(true)
    end

    it { expect_disallowed(:read_label) }

    context 'when group hierarchy has a project with service desk enabled' do
      let_it_be(:subgroup) { create(:group, :private, :crm_enabled, parent: group) }
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
    context 'admin' do
      let(:current_user) { admin }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:update_runners_registration_token) }
      end

      context 'when admin mode is disabled' do
        it { is_expected.to be_disallowed(:update_runners_registration_token) }
      end
    end

    context 'with owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:update_runners_registration_token) }
    end

    context 'with maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_disallowed(:update_runners_registration_token) }
    end

    context 'with reporter' do
      let(:current_user) { reporter }

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
    context 'admin' do
      let(:current_user) { admin }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:register_group_runners) }

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

          context 'with specific group runner registration disabled' do
            before do
              group.runner_registration_enabled = false
            end

            it { is_expected.to be_allowed(:register_group_runners) }
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
    end

    context 'with maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_disallowed(:register_group_runners) }
    end

    context 'with reporter' do
      let(:current_user) { reporter }

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

    context 'create_runner_workflow_for_namespace flag enabled' do
      before do
        stub_feature_flags(create_runner_workflow_for_namespace: [group])
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

    context 'with create_runner_workflow_for_namespace flag disabled' do
      before do
        stub_feature_flags(create_runner_workflow_for_namespace: [other_group])
      end

      let_it_be(:other_group) { create(:group) }

      context 'admin' do
        let(:current_user) { admin }

        context 'when admin mode is enabled', :enable_admin_mode do
          it { is_expected.to be_disallowed(:create_runner) }

          context 'with specific group runner registration disabled' do
            before do
              group.runner_registration_enabled = false
            end

            it { is_expected.to be_disallowed(:create_runner) }
          end

          it_behaves_like 'disallowed when group runner registration disabled'
        end

        context 'when admin mode is disabled' do
          it { is_expected.to be_disallowed(:create_runner) }
        end
      end

      context 'with owner' do
        let(:current_user) { owner }

        it { is_expected.to be_disallowed(:create_runner) }

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
  end

  describe 'read_group_all_available_runners' do
    context 'admin' do
      let(:current_user) { admin }

      context 'when admin mode is enabled', :enable_admin_mode do
        specify { is_expected.to be_allowed(:read_group_all_available_runners) }
      end

      context 'when admin mode is disabled' do
        specify { is_expected.to be_disallowed(:read_group_all_available_runners) }
      end
    end

    context 'with owner' do
      let(:current_user) { owner }

      specify { is_expected.to be_allowed(:read_group_all_available_runners) }
    end

    context 'with maintainer' do
      let(:current_user) { maintainer }

      specify { is_expected.to be_allowed(:read_group_all_available_runners) }
    end

    context 'with developer' do
      let(:current_user) { developer }

      specify { is_expected.to be_allowed(:read_group_all_available_runners) }
    end

    context 'with reporter' do
      let(:current_user) { reporter }

      specify { is_expected.to be_disallowed(:read_group_all_available_runners) }
    end

    context 'with guest' do
      let(:current_user) { guest }

      specify { is_expected.to be_disallowed(:read_group_all_available_runners) }
    end

    context 'with non member' do
      let(:current_user) { create(:user) }

      specify { is_expected.to be_disallowed(:read_group_all_available_runners) }
    end

    context 'with anonymous' do
      let(:current_user) { nil }

      specify { is_expected.to be_disallowed(:read_group_all_available_runners) }
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
      group.crm_settings.update!(enabled: false)
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

    specify { is_expected.to be_allowed(:read_achievement) }
    specify { is_expected.to be_allowed(:admin_achievement) }
    specify { is_expected.to be_allowed(:award_achievement) }

    context 'with feature flag disabled' do
      before do
        stub_feature_flags(achievements: false)
      end

      specify { is_expected.to be_disallowed(:read_achievement) }
      specify { is_expected.to be_disallowed(:admin_achievement) }
      specify { is_expected.to be_disallowed(:award_achievement) }
    end
  end
end
