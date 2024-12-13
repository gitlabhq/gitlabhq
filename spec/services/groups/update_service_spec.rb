# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::UpdateService, feature_category: :groups_and_projects do
  let!(:user) { create(:user) }
  let!(:private_group) { create(:group, :private) }
  let!(:internal_group) { create(:group, :internal) }
  let!(:public_group) { create(:group, :public) }

  describe "#execute" do
    context 'with project' do
      let!(:group) { create(:group, :public) }
      let(:project) { create(:project, namespace: group) }

      context 'located in a subgroup' do
        let(:subgroup) { create(:group, parent: group) }
        let!(:project) { create(:project, namespace: subgroup) }

        before do
          subgroup.add_owner(user)
        end

        it 'does allow a path update if there is not a root namespace change' do
          expect(update_group(subgroup, user, path: 'updated')).to be true
          expect(subgroup.errors[:path]).to be_empty
        end
      end
    end

    context "project visibility_level validation" do
      context "public group with public projects" do
        let!(:service) { described_class.new(public_group, user, visibility_level: Gitlab::VisibilityLevel::INTERNAL) }

        before do
          public_group.add_member(user, Gitlab::Access::OWNER)
          create(:project, :public, group: public_group)

          expect(TodosDestroyer::GroupPrivateWorker).not_to receive(:perform_in)
        end

        it "does not change permission level" do
          service.execute
          expect(public_group.errors.count).to eq(1)

          expect(TodosDestroyer::GroupPrivateWorker).not_to receive(:perform_in)
        end

        it "returns false if save failed" do
          allow(public_group).to receive(:save).and_return(false)

          expect(service.execute).to be_falsey
        end

        context 'when a project has container images' do
          let(:params) { { path: SecureRandom.hex } }
          let!(:container_repository) { create(:container_repository, project: project) }

          subject { described_class.new(public_group, user, params).execute }

          context 'within group' do
            let(:project) { create(:project, group: public_group) }

            context 'with path updates' do
              it 'does not allow the update' do
                expect(subject).to be false
                expect(public_group.errors[:base].first).to match(/Docker images in their Container Registry/)
              end
            end

            context 'with name updates' do
              let(:params) { { name: 'new-name' } }

              it 'allows the update' do
                expect(subject).to be true
                expect(public_group.reload.name).to eq('new-name')
              end
            end

            context 'when the path does not change' do
              let(:params) { { name: 'new-name', path: public_group.path } }

              it 'allows the update' do
                expect(subject).to be true
                expect(public_group.reload.name).to eq('new-name')
              end
            end
          end

          context 'within subgroup' do
            let(:subgroup) { create(:group, parent: public_group) }
            let(:project) { create(:project, group: subgroup) }

            it 'does not allow path updates' do
              expect(subject).to be false
              expect(public_group.errors[:base].first).to match(/Docker images in their Container Registry/)
            end
          end
        end
      end

      context "internal group with internal project" do
        let!(:service) { described_class.new(internal_group, user, visibility_level: Gitlab::VisibilityLevel::PRIVATE) }

        before do
          internal_group.add_member(user, Gitlab::Access::OWNER)
          create(:project, :internal, group: internal_group)

          expect(TodosDestroyer::GroupPrivateWorker).not_to receive(:perform_in)
        end

        it "does not change permission level" do
          service.execute
          expect(internal_group.errors.count).to eq(1)
        end
      end

      context "internal group with private project" do
        let!(:service) { described_class.new(internal_group, user, visibility_level: Gitlab::VisibilityLevel::PRIVATE) }

        before do
          internal_group.add_member(user, Gitlab::Access::OWNER)
          create(:project, :private, group: internal_group)

          expect(TodosDestroyer::GroupPrivateWorker).to receive(:perform_in)
            .with(Todo::WAIT_FOR_DELETE, internal_group.id)
        end

        it "changes permission level to private" do
          service.execute
          expect(internal_group.visibility_level)
            .to eq(Gitlab::VisibilityLevel::PRIVATE)
        end
      end
    end

    context "with parent_id user doesn't have permissions for" do
      let(:service) { described_class.new(public_group, user, parent_id: private_group.id) }

      before do
        service.execute
      end

      it 'does not update parent_id' do
        updated_group = public_group.reload

        expect(updated_group.parent_id).to be_nil
      end
    end

    context 'crm params' do
      let(:params) { {} }

      context 'when no existing crm_settings' do
        it 'when params not present, leave crm enabled' do
          described_class.new(public_group, user, params).execute
          updated_group = public_group.reload

          expect(updated_group.crm_enabled?).to be_truthy
        end

        it 'when crm_enabled param set false, disables crm' do
          params = { crm_enabled: false }

          described_class.new(public_group, user, params).execute
          updated_group = public_group.reload

          expect(updated_group.crm_enabled?).to be_falsy
        end

        it 'when crm_source_group_id present, updates crm_group' do
          params = { crm_source_group_id: internal_group.id }

          described_class.new(public_group, user, params).execute
          updated_group = public_group.reload

          expect(updated_group.crm_enabled?).to be_truthy
          expect(updated_group.crm_group).to eq(internal_group)
        end
      end

      context 'with existing crm_settings' do
        let(:init_enabled) { true }

        before do
          create(:crm_settings, group: public_group, enabled: init_enabled)
        end

        context 'when crm initially disabled' do
          let(:init_enabled) { false }

          context 'when crm_enabled param set true' do
            let(:params) { { crm_enabled: true } }

            it 'enables crm' do
              described_class.new(public_group, user, params).execute

              updated_group = public_group.reload
              expect(updated_group.crm_enabled?).to be_truthy
            end
          end

          it 'when crm_enabled param not present, crm remains disabled' do
            described_class.new(public_group, user, params).execute

            updated_group = public_group.reload
            expect(updated_group.crm_enabled?).to be_falsy
          end
        end

        context 'when crm_enabled param set false' do
          let(:init_enabled) { true }
          let(:params) { { crm_enabled: false } }

          it 'disables crm' do
            described_class.new(public_group, user, params).execute

            updated_group = public_group.reload
            expect(updated_group.crm_enabled?).to be_falsy
          end
        end

        it 'when crm_enabled param not present, crm remains enabled' do
          described_class.new(public_group, user, params).execute

          updated_group = public_group.reload
          expect(updated_group.crm_enabled?).to be_truthy
        end

        context 'when crm_source_group_id present' do
          let(:params) { { crm_source_group_id: internal_group.id } }

          it 'updates crm_group' do
            described_class.new(public_group, user, params).execute
            updated_group = public_group.reload

            expect(updated_group.crm_enabled?).to be_truthy
            expect(updated_group.crm_settings.source_group).to eq(internal_group)
            expect(updated_group.crm_group).to eq(internal_group)
          end
        end

        context 'when crm_source_group_id blank' do
          let(:params) { { crm_source_group_id: '' } }

          it 'clears source_group and resets crm_group' do
            described_class.new(public_group, user, params).execute
            updated_group = public_group.reload

            expect(updated_group.crm_enabled?).to be_truthy
            expect(updated_group.crm_settings.source_group).to be_nil
            expect(updated_group.crm_group).to eq(public_group)
          end
        end
      end

      context 'when changing source' do
        let(:params) { { crm_source_group_id: internal_group.id } }

        context 'when issues do not have contacts' do
          it 'updates crm_group' do
            described_class.new(public_group, user, params).execute
            updated_group = public_group.reload

            expect(updated_group.crm_group).to eq(internal_group)
          end
        end

        context 'when issues do have contacts' do
          let!(:issue) { create(:issue, project: create(:project, group: public_group)) }
          let!(:contact) { create(:contact, group: public_group) }
          let!(:issue_contact) { create(:issue_customer_relations_contact, issue: issue, contact: contact) }

          it 'returns an error and does not update crm_group' do
            described_class.new(public_group, user, params).execute
            updated_group = public_group.reload

            expect(public_group.errors).to contain_exactly('Contact source cannot be changed when issues already have contacts assigned from a different source.')
            expect(updated_group.crm_group).to eq(public_group)
          end
        end
      end
    end
  end

  context "unauthorized visibility_level validation" do
    let!(:service) { described_class.new(internal_group, user, visibility_level: 99) }

    before do
      internal_group.add_member(user, Gitlab::Access::MAINTAINER)
    end

    it "does not change permission level" do
      service.execute
      expect(internal_group.errors.count).to eq(1)
    end
  end

  context "path change validation" do
    let_it_be(:group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:project) { create(:project, namespace: subgroup) }

    subject(:execute_update) { update_group(target_group, user, update_params) }

    shared_examples 'not allowing a path update' do
      let(:update_params) { { path: 'updated' } }

      it 'does not allow a path update' do
        target_group.add_maintainer(user)

        expect(execute_update).to be false
        expect(target_group.errors[:path]).to include('cannot change when group contains projects with NPM packages')
      end
    end

    shared_examples 'allowing an update' do |on:|
      let(:update_params) { { on => 'updated' } }

      it "allows an update on #{on}" do
        target_group.reload.add_maintainer(user)

        expect(execute_update).to be true
        expect(target_group.errors).to be_empty
        expect(target_group[on]).to eq('updated')
      end
    end

    context 'with namespaced npm packages' do
      let_it_be(:package) { create(:npm_package, project: project, name: "@#{group.path}/test") }

      context 'updating the root group' do
        let_it_be_with_refind(:target_group) { group }

        it_behaves_like 'not allowing a path update'
        it_behaves_like 'allowing an update', on: :name
      end

      context 'updating the subgroup' do
        let_it_be_with_refind(:target_group) { subgroup }

        it_behaves_like 'allowing an update', on: :path
        it_behaves_like 'allowing an update', on: :name
      end
    end

    context 'with scoped npm packages' do
      let_it_be(:package) { create(:npm_package, project: project, name: '@any_scope/test') }

      context 'updating the root group' do
        let_it_be_with_refind(:target_group) { group }

        it_behaves_like 'allowing an update', on: :path
        it_behaves_like 'allowing an update', on: :name
      end

      context 'updating the subgroup' do
        let_it_be_with_refind(:target_group) { subgroup }

        it_behaves_like 'allowing an update', on: :path
        it_behaves_like 'allowing an update', on: :name
      end
    end

    context 'with unscoped npm packages' do
      let_it_be(:package) { create(:npm_package, project: project, name: 'test') }

      context 'updating the root group' do
        let_it_be_with_refind(:target_group) { group }

        it_behaves_like 'allowing an update', on: :path
        it_behaves_like 'allowing an update', on: :name
      end

      context 'updating the subgroup' do
        let_it_be_with_refind(:target_group) { subgroup }

        it_behaves_like 'allowing an update', on: :path
        it_behaves_like 'allowing an update', on: :name
      end
    end
  end

  context 'when user is not group owner' do
    context 'when group is private' do
      before do
        private_group.add_maintainer(user)
      end

      it 'does not update the group to public' do
        result = described_class.new(private_group, user, visibility_level: Gitlab::VisibilityLevel::PUBLIC).execute

        expect(result).to eq(false)
        expect(private_group.errors.count).to eq(1)
        expect(private_group).to be_private
      end

      it 'does not update the group to public with tricky value' do
        result = described_class.new(private_group, user, visibility_level: Gitlab::VisibilityLevel::PUBLIC.to_s + 'r').execute

        expect(result).to eq(false)
        expect(private_group.errors.count).to eq(1)
        expect(private_group).to be_private
      end
    end

    context 'when group is public' do
      before do
        public_group.add_maintainer(user)
      end

      it 'does not update the group to private' do
        result = described_class.new(public_group, user, visibility_level: Gitlab::VisibilityLevel::PRIVATE).execute

        expect(result).to eq(false)
        expect(public_group.errors.count).to eq(1)
        expect(public_group).to be_public
      end

      it 'does not update the group to private with invalid string value' do
        result = described_class.new(public_group, user, visibility_level: 'invalid').execute

        expect(result).to eq(false)
        expect(public_group.errors.count).to eq(1)
        expect(public_group).to be_public
      end

      it 'does not update the group to private with valid string value' do
        result = described_class.new(public_group, user, visibility_level: 'private').execute

        expect(result).to eq(false)
        expect(public_group.errors.count).to eq(1)
        expect(public_group).to be_public
      end

      # See https://gitlab.com/gitlab-org/gitlab/-/issues/359910
      it 'does not update the group to private because of Active Record typecasting' do
        result = described_class.new(public_group, user, visibility_level: 'public').execute

        expect(result).to eq(true)
        expect(public_group.errors.count).to eq(0)
        expect(public_group).to be_public
      end
    end
  end

  context 'when updating #emails_enabled' do
    let(:service) { described_class.new(internal_group, user, emails_enabled: false) }

    it 'updates the attribute' do
      internal_group.add_member(user, Gitlab::Access::OWNER)

      expect { service.execute }.to change { internal_group.emails_enabled }.to(false)
    end

    it 'does not update when not group owner' do
      internal_group.add_member(user, Gitlab::Access::MAINTAINER)

      expect { service.execute }.not_to change { internal_group.emails_enabled }
    end
  end

  context 'when updating #max_artifacts_size' do
    let(:params) { { max_artifacts_size: 10 } }

    let(:service) do
      described_class.new(internal_group, user, **params)
    end

    before do
      internal_group.add_owner(user)
    end

    context 'for users who have the ability to update max_artifacts_size', :enable_admin_mode do
      let(:user) { create(:admin) }

      it 'updates max_artifacts_size' do
        expect { service.execute }.to change { internal_group.max_artifacts_size }.from(nil).to(10)
      end
    end

    context 'for users who do not have the ability to update max_artifacts_size' do
      it 'does not update max_artifacts_size' do
        expect { service.execute }.not_to change { internal_group.max_artifacts_size }
      end
    end
  end

  context 'when updating #allow_runner_registration_token' do
    let(:params) { { allow_runner_registration_token: false } }
    let!(:internal_group) { create(:group, :internal, :allow_runner_registration_token) }

    let(:service) do
      described_class.new(internal_group, user, **params)
    end

    context 'for users who have the ability to update allow_runner_registration_token' do
      before do
        internal_group.add_owner(user)
      end

      it 'updates allow_runner_registration_token' do
        expect { service.execute }.to change { internal_group.allow_runner_registration_token }.from(true).to(false)
      end
    end

    context 'for users who do not have the ability to update allow_runner_registration_token' do
      it 'does not update allow_runner_registration_token' do
        expect { service.execute }.not_to change { internal_group.allow_runner_registration_token }
      end
    end
  end

  context 'when updating #math_rendering_limits_enabled' do
    let(:service) { described_class.new(internal_group, user, math_rendering_limits_enabled: false) }

    it 'updates attribute' do
      internal_group.add_member(user, Gitlab::Access::OWNER)

      expect { service.execute }.to change { internal_group.math_rendering_limits_enabled }.to(false)
    end

    it 'does not update when not group owner' do
      internal_group.add_member(user, Gitlab::Access::MAINTAINER)

      expect { service.execute }.not_to change { internal_group.math_rendering_limits_enabled }
    end
  end

  context 'when updating #lock_math_rendering_limits_enabled' do
    let(:service) { described_class.new(internal_group, user, lock_math_rendering_limits_enabled: true) }

    it 'updates attribute' do
      internal_group.add_member(user, Gitlab::Access::OWNER)

      expect { service.execute }.to change { internal_group.lock_math_rendering_limits_enabled? }.to(true)
    end

    it 'does not update when not group owner' do
      internal_group.add_member(user, Gitlab::Access::MAINTAINER)

      expect { service.execute }.not_to change { internal_group.lock_math_rendering_limits_enabled? }
    end
  end

  context 'updating default_branch_protection' do
    let(:service) do
      described_class.new(internal_group, user, default_branch_protection: Gitlab::Access::PROTECTION_DEV_CAN_PUSH)
    end

    let(:settings) { internal_group.namespace_settings }
    let(:expected_settings) { Gitlab::Access::BranchProtection.protection_partial.stringify_keys }

    context 'for users who have the ability to update default_branch_protection' do
      it 'updates default_branch_protection attribute' do
        internal_group.add_owner(user)

        expect { service.execute }.to change { internal_group.default_branch_protection }.from(Gitlab::Access::PROTECTION_FULL).to(Gitlab::Access::PROTECTION_DEV_CAN_PUSH)
      end

      it 'updates default_branch_protection_defaults to match default_branch_protection' do
        internal_group.add_owner(user)

        expect { service.execute }.to change { settings.default_branch_protection_defaults  }.from(Gitlab::Access::BranchProtection.protection_none.stringify_keys).to(expected_settings)
      end
    end

    context 'for users who do not have the ability to update default_branch_protection' do
      it 'does not update the attribute' do
        expect { service.execute }.not_to change { internal_group.default_branch_protection }
        expect { service.execute }.not_to change { internal_group.namespace_settings.default_branch_protection_defaults }
      end
    end
  end

  context 'updating default_branch_protection_defaults' do
    let(:branch_protection) { ::Gitlab::Access::BranchProtection.protected_against_developer_pushes.stringify_keys }

    let(:service) do
      described_class.new(internal_group, user, default_branch_protection_defaults: branch_protection)
    end

    let(:settings) { internal_group.namespace_settings }
    let(:expected_settings) { branch_protection }

    context 'for users who have the ability to update default_branch_protection_defaults' do
      it 'updates default_branch_protection attribute' do
        internal_group.add_owner(user)

        expect { service.execute }.to change { internal_group.default_branch_protection_defaults }.from(Gitlab::Access::BranchProtection.protection_none.deep_stringify_keys).to(expected_settings)
      end
    end

    context 'for users who do not have the ability to update default_branch_protection_defaults' do
      it 'does not update the attribute' do
        expect { service.execute }.not_to change { internal_group.default_branch_protection_defaults }
        expect { service.execute }.not_to change { internal_group.namespace_settings.default_branch_protection_defaults }
      end
    end
  end

  context 'when setting enable_namespace_descendants_cache' do
    let(:params) { { enable_namespace_descendants_cache: true } }

    subject(:result) { described_class.new(public_group, user, params).execute }

    context 'when the group_hierarchy_optimization feature flag is enabled' do
      before do
        stub_feature_flags(group_hierarchy_optimization: true)
      end

      context 'when enabling the setting' do
        it 'creates the initial Namespaces::Descendants record' do
          expect { result }.to change { public_group.reload.namespace_descendants.present? }.from(false).to(true)

          expect(public_group.namespace_descendants.outdated_at).to be_present
        end
      end

      context 'when accidentally enabling the setting again' do
        it 'does nothing' do
          namespace_descendants = create(:namespace_descendants, namespace: public_group)

          expect { result }.not_to change { namespace_descendants.reload }
        end
      end

      context 'when disabling the setting' do
        before do
          params[:enable_namespace_descendants_cache] = false
        end

        it 'removes the Namespaces::Descendants record' do
          create(:namespace_descendants, namespace: public_group)

          expect { result }.to change { public_group.reload.namespace_descendants }.to(nil)
        end

        context 'when the Namespaces::Descendants record is missing' do
          it 'does not raise error' do
            expect { result }.not_to raise_error
          end
        end
      end
    end

    context 'when the group_hierarchy_optimization feature flag is disabled' do
      before do
        stub_feature_flags(group_hierarchy_optimization: false)
      end

      it 'does nothing' do
        expect { result }.not_to change { public_group.reload.namespace_descendants.present? }.from(false)
      end
    end
  end

  context 'EventStore' do
    let(:service) { described_class.new(group, user, **params) }
    let(:root_group) { create(:group, path: 'root') }
    let(:group) do
      create(:group, parent: root_group, path: 'old-path', owners: user)
    end

    context 'when changing a group path' do
      let(:new_path) { SecureRandom.hex }
      let(:params) { { path: new_path } }

      it 'publishes a GroupPathChangedEvent' do
        old_path = group.full_path

        expect { service.execute }
          .to publish_event(Groups::GroupPathChangedEvent)
          .with(
            group_id: group.id,
            root_namespace_id: group.root_ancestor.id,
            old_path: old_path,
            new_path: "root/#{new_path}"
          )
      end
    end

    context 'when not changing a group path' do
      let(:params) { { name: 'very-new-name' } }

      it 'does not publish a GroupPathChangedEvent' do
        expect { service.execute }
          .not_to publish_event(Groups::GroupPathChangedEvent)
      end
    end
  end

  context 'rename group' do
    let(:new_path) { SecureRandom.hex }
    let!(:service) { described_class.new(internal_group, user, path: new_path) }

    before do
      internal_group.add_member(user, Gitlab::Access::MAINTAINER)
      create(:project, :internal, group: internal_group)
    end

    it 'returns true' do
      expect(service.execute).to eq(true)
    end
  end

  context 'for a subgroup' do
    let(:subgroup) { create(:group, :private, parent: private_group) }

    context 'when the parent group share_with_group_lock is enabled' do
      before do
        private_group.update_column(:share_with_group_lock, true)
      end

      context 'for the parent group owner' do
        it 'allows disabling share_with_group_lock' do
          private_group.add_owner(user)

          result = described_class.new(subgroup, user, share_with_group_lock: false).execute

          expect(result).to be_truthy
          expect(subgroup.reload.share_with_group_lock).to be_falsey
        end
      end

      context 'for a subgroup owner (who does not own the parent)' do
        it 'does not allow disabling share_with_group_lock' do
          subgroup_owner = create(:user)
          subgroup.add_owner(subgroup_owner)

          result = described_class.new(subgroup, subgroup_owner, share_with_group_lock: false).execute

          expect(result).to be_falsey
          expect(subgroup.errors.full_messages.first).to match(/cannot be disabled when the parent group "Share with group lock" is enabled, except by the owner of the parent group/)
          expect(subgroup.reload.share_with_group_lock).to be_truthy
        end
      end
    end
  end

  context 'change shared Runners config' do
    let(:group) { create(:group) }
    let(:project) { create(:project, shared_runners_enabled: true, group: group) }

    subject { described_class.new(group, user, shared_runners_setting: Namespace::SR_DISABLED_AND_UNOVERRIDABLE).execute }

    before do
      group.add_owner(user)
    end

    it 'calls the shared runners update service' do
      expect_any_instance_of(::Groups::UpdateSharedRunnersService).to receive(:execute).and_return({ status: :success })

      expect(subject).to be_truthy
    end

    it 'handles errors in the shared runners update service' do
      expect_any_instance_of(::Groups::UpdateSharedRunnersService).to receive(:execute).and_return({ status: :error, message: 'something happened' })

      expect(subject).to be_falsy

      expect(group.errors[:update_shared_runners].first).to eq('something happened')
    end
  end

  context 'changes allowing subgroups to establish own 2FA' do
    let(:group) { create(:group) }
    let(:params) { { allow_mfa_for_subgroups: false } }

    subject { described_class.new(group, user, params).execute }

    it 'changes settings' do
      subject

      expect(group.namespace_settings.reload.allow_mfa_for_subgroups).to eq(false)
    end

    it 'enqueues update subgroups and its members' do
      expect(DisallowTwoFactorForSubgroupsWorker).to receive(:perform_async).with(group.id)

      subject
    end
  end

  def update_group(group, user, opts)
    Groups::UpdateService.new(group, user, opts).execute
  end
end
