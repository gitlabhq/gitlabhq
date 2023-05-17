# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::UpdateService, feature_category: :subgroups do
  let!(:user) { create(:user) }
  let!(:private_group) { create(:group, :private) }
  let!(:internal_group) { create(:group, :internal) }
  let!(:public_group) { create(:group, :public) }

  describe "#execute" do
    shared_examples 'with packages' do
      before do
        group.add_owner(user)
      end

      context 'with npm packages' do
        let!(:package) { create(:npm_package, project: project) }

        it 'does not allow a path update' do
          expect(update_group(group, user, path: 'updated')).to be false
          expect(group.errors[:path]).to include('cannot change when group contains projects with NPM packages')
        end

        it 'allows name update' do
          expect(update_group(group, user, name: 'Updated')).to be true
          expect(group.errors).to be_empty
          expect(group.name).to eq('Updated')
        end
      end
    end

    context 'with project' do
      let!(:group) { create(:group, :public) }
      let(:project) { create(:project, namespace: group) }

      it_behaves_like 'with packages'

      context 'located in a subgroup' do
        let(:subgroup) { create(:group, parent: group) }
        let!(:project) { create(:project, namespace: subgroup) }

        before do
          subgroup.add_owner(user)
        end

        it_behaves_like 'with packages'

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

    context 'crm_enabled param' do
      context 'when no existing crm_settings' do
        it 'when param not present, leave crm disabled' do
          params = {}

          described_class.new(public_group, user, params).execute
          updated_group = public_group.reload

          expect(updated_group.crm_enabled?).to be_falsey
        end

        it 'when param set true, enables crm' do
          params = { crm_enabled: true }

          described_class.new(public_group, user, params).execute
          updated_group = public_group.reload

          expect(updated_group.crm_enabled?).to be_truthy
        end
      end

      context 'with existing crm_settings' do
        it 'when param set true, enables crm' do
          params = { crm_enabled: true }
          create(:crm_settings, group: public_group)

          described_class.new(public_group, user, params).execute

          updated_group = public_group.reload
          expect(updated_group.crm_enabled?).to be_truthy
        end

        it 'when param set false, disables crm' do
          params = { crm_enabled: false }
          create(:crm_settings, group: public_group, enabled: true)

          described_class.new(public_group, user, params).execute

          updated_group = public_group.reload
          expect(updated_group.crm_enabled?).to be_falsy
        end

        it 'when param not present, crm remains disabled' do
          params = {}
          create(:crm_settings, group: public_group)

          described_class.new(public_group, user, params).execute

          updated_group = public_group.reload
          expect(updated_group.crm_enabled?).to be_falsy
        end

        it 'when param not present, crm remains enabled' do
          params = {}
          create(:crm_settings, group: public_group, enabled: true)

          described_class.new(public_group, user, params).execute

          updated_group = public_group.reload
          expect(updated_group.crm_enabled?).to be_truthy
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

  context 'when updating #emails_disabled' do
    let(:service) { described_class.new(internal_group, user, emails_disabled: true) }

    it 'updates the attribute' do
      internal_group.add_member(user, Gitlab::Access::OWNER)

      expect { service.execute }.to change { internal_group.emails_disabled }.to(true)
    end

    it 'does not update when not group owner' do
      expect { service.execute }.not_to change { internal_group.emails_disabled }
    end
  end

  context 'updating default_branch_protection' do
    let(:service) do
      described_class.new(internal_group, user, default_branch_protection: Gitlab::Access::PROTECTION_NONE)
    end

    context 'for users who have the ability to update default_branch_protection' do
      it 'updates the attribute' do
        internal_group.add_owner(user)

        expect { service.execute }.to change { internal_group.default_branch_protection }.to(Gitlab::Access::PROTECTION_NONE)
      end
    end

    context 'for users who do not have the ability to update default_branch_protection' do
      it 'does not update the attribute' do
        expect { service.execute }.not_to change { internal_group.default_branch_protection }
      end
    end
  end

  context 'EventStore' do
    let(:service) { described_class.new(group, user, **params) }
    let(:root_group) { create(:group, path: 'root') }
    let(:group) do
      create(:group, parent: root_group, path: 'old-path').tap { |g| g.add_owner(user) }
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

    context 'error moving group' do
      before do
        allow(internal_group).to receive(:move_dir).and_raise(Gitlab::UpdatePathError)
      end

      it 'does not raise an error' do
        expect { service.execute }.not_to raise_error
      end

      it 'returns false' do
        expect(service.execute).to eq(false)
      end

      it 'has the right error' do
        service.execute

        expect(internal_group.errors.full_messages.first).to eq('Gitlab::UpdatePathError')
      end

      it "hasn't changed the path" do
        expect { service.execute }.not_to change { internal_group.reload.path }
      end
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
