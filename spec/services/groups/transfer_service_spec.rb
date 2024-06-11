# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::TransferService, :sidekiq_inline, feature_category: :groups_and_projects do
  shared_examples 'project namespace path is in sync with project path' do
    it 'keeps project and project namespace attributes in sync' do
      projects_with_project_namespace.each do |project|
        project.reload

        expect(project.full_path).to eq("#{group_full_path}/#{project.path}")
        expect(project.project_namespace.full_path).to eq(project.full_path)
        expect(project.project_namespace.parent).to eq(project.namespace)
        expect(project.project_namespace.visibility_level).to eq(project.visibility_level)
      end
    end
  end

  let_it_be(:user) { create(:user) }
  let_it_be(:new_parent_group) { create(:group, :public) }

  let!(:group_member) { create(:group_member, :owner, group: group, user: user) }
  let(:transfer_service) { described_class.new(group, user) }

  shared_examples 'publishes a GroupTransferedEvent' do
    it do
      expect { transfer_service.execute(target) }
        .to publish_event(Groups::GroupTransferedEvent)
        .with(
          group_id: group.id,
          old_root_namespace_id: group.root_ancestor.id,
          new_root_namespace_id: target.root_ancestor.id
        )
    end
  end

  context 'handling packages' do
    let_it_be(:group) { create(:group) }
    let_it_be(:new_group) { create(:group) }

    let_it_be(:project) { create(:project, namespace: group) }

    before do
      group.add_owner(user)
      new_group&.add_owner(user)
    end

    context 'with an npm package' do
      let_it_be(:npm_package) { create(:npm_package, project: project, name: "@testscope/test") }

      shared_examples 'transfer allowed' do
        it 'allows transfer' do
          transfer_service.execute(new_group)

          expect(transfer_service.error).to be nil
          expect(group.parent).to eq(new_group)
        end
      end

      it_behaves_like 'transfer allowed'

      context 'with a project within subgroup' do
        let_it_be(:root_group) { create(:group) }
        let_it_be_with_reload(:group) { create(:group, parent: root_group) }
        let_it_be(:project) { create(:project, namespace: group) }

        before do
          root_group.add_owner(user)
        end

        it_behaves_like 'transfer allowed'

        context 'without a root namespace change' do
          let_it_be(:new_group) { create(:group, parent: root_group) }

          it_behaves_like 'transfer allowed'
        end

        context 'with namespaced packages present' do
          let_it_be(:package) { create(:npm_package, project: project, name: "@#{project.root_namespace.path}/test") }

          it 'does not allow transfer' do
            transfer_service.execute(new_group)

            expect(transfer_service.error).to eq('Transfer failed: Group contains projects with NPM packages scoped to the current root level group.')
            expect(group.parent).not_to eq(new_group)
          end

          context 'namespaced package is pending destruction' do
            let!(:group) { create(:group) }

            before do
              package.pending_destruction!
            end

            it_behaves_like 'transfer allowed'
          end
        end

        context 'when transferring a group into a root group' do
          let_it_be(:root_group) { create(:group) }
          let_it_be(:group) { create(:group, parent: root_group) }
          let_it_be(:new_group) { nil }

          it_behaves_like 'transfer allowed'
        end
      end
    end

    context 'without an npm package' do
      context 'when transferring a group into a root group' do
        let(:group) { create(:group, parent: create(:group)) }

        it 'allows transfer' do
          transfer_service.execute(nil)

          expect(transfer_service.error).to be nil
          expect(group.parent).to be_nil
        end
      end
    end
  end

  shared_examples 'ensuring allowed transfer for a group' do
    context "when there's an exception on GitLab shell directories" do
      before do
        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:update_group_attributes).and_raise(Gitlab::UpdatePathError, 'namespace directory cannot be moved')
        end
        create(:group_member, :owner, group: new_parent_group, user: user)
      end

      it 'returns false' do
        expect(transfer_service.execute(new_parent_group)).to be_falsy
      end

      it 'adds an error on group' do
        transfer_service.execute(new_parent_group)
        expect(transfer_service.error).to eq('Transfer failed: namespace directory cannot be moved')
      end
    end
  end

  context 'transferring labels' do
    let(:new_parent_group) { create(:group, :private) }
    let(:parent_group) { create(:group) }
    let(:group) { create(:group, parent: parent_group) }
    let(:project) { create(:project, group: group) }

    before do
      group.add_owner(user)
      parent_group.add_owner(user)
      new_parent_group.add_owner(user)
    end

    it 'delegates transfer to Labels::TransferService' do
      expect_next_instance_of(Labels::TransferService, user, project.group, project) do |labels_transfer_service|
        expect(labels_transfer_service).to receive(:execute).once.and_call_original
      end

      transfer_service.execute(new_parent_group)
    end
  end

  describe '#execute' do
    context 'when transforming a group into a root group' do
      let_it_be_with_reload(:group) { create(:group, :public, :nested) }

      it_behaves_like 'ensuring allowed transfer for a group'

      context 'when the group is already a root group' do
        let(:group) { create(:group, :public) }

        it 'adds an error on group' do
          transfer_service.execute(nil)
          expect(transfer_service.error).to eq('Transfer failed: Group is already a root group.')
        end
      end

      context 'when the user does not have the right policies' do
        let_it_be(:group_member) { create(:group_member, :guest, group: group, user: user) }

        it "returns false" do
          expect(transfer_service.execute(nil)).to be_falsy
        end

        it "adds an error on group" do
          transfer_service.execute(new_parent_group)
          expect(transfer_service.error).to eq("Transfer failed: You don't have enough permissions.")
        end
      end

      context 'when there is a group with the same path' do
        let_it_be(:group) { create(:group, :public, :nested, path: 'not-unique') }

        before do
          create(:group, path: 'not-unique')
        end

        it 'returns false' do
          expect(transfer_service.execute(nil)).to be_falsy
        end

        it 'adds an error on group' do
          transfer_service.execute(nil)
          expect(transfer_service.error).to eq('Transfer failed: The parent group already has a subgroup or a project with the same path.')
        end
      end

      context 'when the group is a subgroup and the transfer is valid' do
        let_it_be(:subgroup1) { create(:group, :private, parent: group) }
        let_it_be(:subgroup2) { create(:group, :internal, parent: group) }
        let_it_be(:project1) { create(:project, :repository, :private, namespace: group) }

        before do
          transfer_service.execute(nil)
          group.reload
        end

        it 'updates group attributes' do
          expect(group.parent).to be_nil
        end

        it 'updates group children path' do
          group.children.each do |subgroup|
            expect(subgroup.full_path).to eq("#{group.path}/#{subgroup.path}")
          end
        end

        it 'updates group projects path' do
          group.projects.each do |project|
            expect(project.full_path).to eq("#{group.path}/#{project.path}")
          end
        end

        context 'when projects have project namespaces' do
          let_it_be(:project1) { create(:project, :private, namespace: group) }
          let_it_be(:project2) { create(:project, :private, namespace: group) }

          it_behaves_like 'project namespace path is in sync with project path' do
            let(:group_full_path) { group.path.to_s }
            let(:projects_with_project_namespace) { [project1, project2] }
          end
        end
      end
    end

    context 'when transferring a subgroup into another group' do
      let_it_be_with_reload(:group) { create(:group, :public, :nested) }

      it_behaves_like 'ensuring allowed transfer for a group'

      context 'when the new parent group is the same as the previous parent group' do
        let_it_be(:group) { create(:group, :public, :nested, parent: new_parent_group) }

        it 'returns false' do
          expect(transfer_service.execute(new_parent_group)).to be_falsy
        end

        it 'adds an error on group' do
          transfer_service.execute(new_parent_group)
          expect(transfer_service.error).to eq('Transfer failed: Group is already associated to the parent group.')
        end
      end

      context 'when the user does not have the right policies' do
        let_it_be(:group_member) { create(:group_member, :guest, group: group, user: user) }

        it "returns false" do
          expect(transfer_service.execute(new_parent_group)).to be_falsy
        end

        it "adds an error on group" do
          transfer_service.execute(new_parent_group)
          expect(transfer_service.error).to eq("Transfer failed: You don't have enough permissions.")
        end
      end

      context 'when the parent has a group with the same path' do
        before do
          create(:group_member, :owner, group: new_parent_group, user: user)
          group.update_attribute(:path, "not-unique")
          create(:group, path: "not-unique", parent: new_parent_group)
        end

        it 'returns false' do
          expect(transfer_service.execute(new_parent_group)).to be_falsy
        end

        it 'adds an error on group' do
          transfer_service.execute(new_parent_group)
          expect(transfer_service.error).to eq('Transfer failed: The parent group already has a subgroup or a project with the same path.')
        end
      end

      context 'when the parent group has a project with the same path' do
        let_it_be_with_reload(:group) { create(:group, :public, :nested, path: 'foo') }
        let_it_be(:membership) { create(:group_member, :owner, group: new_parent_group, user: user) }
        let_it_be(:project) { create(:project, path: 'foo', namespace: new_parent_group) }

        it 'adds an error on group' do
          expect(transfer_service.execute(new_parent_group)).to be_falsy
          expect(transfer_service.error).to eq('Transfer failed: The parent group already has a subgroup or a project with the same path.')
        end
      end

      context 'when projects have project namespaces' do
        let_it_be(:project) { create(:project, path: 'foo', namespace: new_parent_group) }

        before do
          transfer_service.execute(new_parent_group)
        end

        it_behaves_like 'project namespace path is in sync with project path' do
          let(:group_full_path) { new_parent_group.full_path.to_s }
          let(:projects_with_project_namespace) { [project] }
        end
      end

      context 'when the group is allowed to be transferred' do
        let_it_be(:new_parent_group, reload: true) { create(:group, :public) }
        let_it_be(:new_parent_group_integration) { create(:integrations_slack, :group, group: new_parent_group, webhook: 'http://new-group.slack.com') }

        before do
          allow(PropagateIntegrationWorker).to receive(:perform_async)

          create(:group_member, :owner, group: new_parent_group, user: user)

          transfer_service.execute(new_parent_group)
        end

        context 'when the group has a lower visibility than the parent group' do
          let(:new_parent_group) { create(:group, :public) }
          let(:group) { create(:group, :private, :nested) }

          it 'does not update the visibility for the group' do
            group.reload
            expect(group.private?).to be_truthy
            expect(group.visibility_level).not_to eq(new_parent_group.visibility_level)
          end
        end

        context 'when the group has a higher visibility than the parent group' do
          let(:new_parent_group) { create(:group, :private) }
          let(:group) { create(:group, :public, :nested) }

          it 'updates visibility level based on the parent group' do
            group.reload
            expect(group.private?).to be_truthy
            expect(group.visibility_level).to eq(new_parent_group.visibility_level)
          end
        end

        context 'with a group integration' do
          let(:new_created_integration) { Integration.find_by(group: group) }

          context 'with an inherited integration' do
            let_it_be(:instance_integration) { create(:integrations_slack, :instance, webhook: 'http://project.slack.com') }
            let_it_be(:group_integration) { create(:integrations_slack, :group, group: group, webhook: 'http://group.slack.com', inherit_from_id: instance_integration.id) }

            it 'replaces inherited integrations', :aggregate_failures do
              expect(new_created_integration.webhook).to eq(new_parent_group_integration.webhook)
              expect(PropagateIntegrationWorker).to have_received(:perform_async).with(new_created_integration.id)
              expect(Integration.count).to eq(3)
            end
          end

          context 'with instance specific integration' do
            let_it_be(:instance_specific_integration) { create(:beyond_identity_integration) }
            let_it_be(:group_instance_specific_integration) do
              create(
                :beyond_identity_integration,
                group: group,
                instance: false,
                active: true,
                inherit_from_id: instance_specific_integration.id
              )
            end

            let_it_be(:parent_group_instance_specific_integration) do
              create(:beyond_identity_integration, group: new_parent_group, instance: false, active: false)
            end

            it 'replaces inherited integrations', :aggregate_failures do
              new_group_instance_specific_integration = Integration.find_by(group: group, type: instance_specific_integration.type)
              expect(new_group_instance_specific_integration.inherit_from_id).to eq(parent_group_instance_specific_integration.id)
              expect(new_group_instance_specific_integration.active).to be_falsey
              expect(PropagateIntegrationWorker).to have_received(:perform_async).with(new_group_instance_specific_integration.id)
              expect(Integration.count).to eq(5)
            end
          end

          context 'with a custom integration' do
            let_it_be(:group_integration) { create(:integrations_slack, :group, group: group, webhook: 'http://group.slack.com') }

            it 'does not updates the integrations', :aggregate_failures do
              expect { transfer_service.execute(new_parent_group) }.not_to change { group_integration.webhook }
              expect(PropagateIntegrationWorker).not_to have_received(:perform_async)
            end
          end
        end

        it 'updates visibility for the group based on the parent group' do
          expect(group.visibility_level).to eq(new_parent_group.visibility_level)
        end

        it 'updates parent group to the new parent' do
          expect(group.parent).to eq(new_parent_group)
        end

        it 'returns the group as children of the new parent' do
          expect(new_parent_group.children.count).to eq(1)
          expect(new_parent_group.children.first).to eq(group)
        end

        it 'creates a redirect for the group' do
          expect(group.redirect_routes.count).to eq(1)
        end
      end

      context 'shared runners configuration' do
        before do
          create(:group_member, :owner, group: new_parent_group, user: user)
        end

        context 'if parent group has disabled shared runners but allows overrides' do
          let(:new_parent_group) { create(:group, shared_runners_enabled: false, allow_descendants_override_disabled_shared_runners: true) }

          it 'calls update service' do
            expect(Groups::UpdateSharedRunnersService).to receive(:new).with(group, user, { shared_runners_setting: Namespace::SR_DISABLED_AND_OVERRIDABLE }).and_call_original

            transfer_service.execute(new_parent_group)
          end
        end

        context 'if parent group does not allow shared runners' do
          let(:new_parent_group) { create(:group, shared_runners_enabled: false, allow_descendants_override_disabled_shared_runners: false) }

          it 'calls update service' do
            expect(Groups::UpdateSharedRunnersService).to receive(:new).with(group, user, { shared_runners_setting: Namespace::SR_DISABLED_AND_UNOVERRIDABLE }).and_call_original

            transfer_service.execute(new_parent_group)
          end
        end

        context 'if parent group allows shared runners' do
          let(:group) { create(:group, :public, :nested, shared_runners_enabled: false) }
          let(:new_parent_group) { create(:group, shared_runners_enabled: true) }

          it 'does not call update service and keeps them disabled on the group' do
            expect(Groups::UpdateSharedRunnersService).not_to receive(:new)

            transfer_service.execute(new_parent_group)
            expect(group.reload.shared_runners_enabled).to be_falsy
          end
        end
      end

      context 'when a group is transferred to its subgroup' do
        let(:new_parent_group) { create(:group, parent: group) }

        it 'does not execute the transfer' do
          expect(transfer_service.execute(new_parent_group)).to be_falsy
          expect(transfer_service.error).to match(/Cannot transfer group to one of its subgroup/)
        end
      end

      context 'when transferring a group with group descendants' do
        let!(:subgroup1) { create(:group, :private, parent: group) }
        let!(:subgroup2) { create(:group, :internal, parent: group) }

        before do
          create(:group_member, :owner, group: new_parent_group, user: user)
          transfer_service.execute(new_parent_group)
        end

        it 'updates subgroups path' do
          new_parent_path = new_parent_group.path
          group.children.each do |subgroup|
            expect(subgroup.full_path).to eq("#{new_parent_path}/#{group.path}/#{subgroup.path}")
          end
        end

        it 'creates redirects for the subgroups' do
          expect(group.redirect_routes.count).to eq(1)
          expect(subgroup1.redirect_routes.count).to eq(1)
          expect(subgroup2.redirect_routes.count).to eq(1)
        end

        context 'when the new parent has a higher visibility than the children' do
          it 'does not update the children visibility' do
            expect(subgroup1.private?).to be_truthy
            expect(subgroup2.internal?).to be_truthy
          end
        end

        context 'when the new parent has a lower visibility than the children' do
          let!(:subgroup1) { create(:group, :public, parent: group) }
          let!(:subgroup2) { create(:group, :public, parent: group) }
          let(:new_parent_group) { create(:group, :private) }

          it 'updates children visibility to match the new parent' do
            group.children.each do |subgroup|
              expect(subgroup.private?).to be_truthy
            end
          end
        end
      end

      context 'when transferring a group with project descendants' do
        let!(:project1) { create(:project, :repository, :private, namespace: group) }
        let!(:project2) { create(:project, :repository, :internal, namespace: group) }

        before do
          TestEnv.clean_test_path
          create(:group_member, :owner, group: new_parent_group, user: user)
          allow(transfer_service).to receive(:update_project_settings)
          transfer_service.execute(new_parent_group)
        end

        it 'updates projects path' do
          new_parent_path = new_parent_group.path
          group.projects.each do |project|
            expect(project.full_path).to eq("#{new_parent_path}/#{group.path}/#{project.path}")
          end
        end

        it 'creates permanent redirects for the projects' do
          expect(group.redirect_routes.count).to eq(1)
          expect(project1.redirect_routes.count).to eq(1)
          expect(project2.redirect_routes.count).to eq(1)
        end

        context 'when the new parent has a higher visibility than the projects' do
          it 'does not update projects visibility' do
            expect(project1.private?).to be_truthy
            expect(project2.internal?).to be_truthy
          end

          it_behaves_like 'project namespace path is in sync with project path' do
            let(:group_full_path) { "#{new_parent_group.path}/#{group.path}" }
            let(:projects_with_project_namespace) { [project1, project2] }
          end
        end

        context 'when the new parent has a lower visibility than the projects' do
          let!(:project1) { create(:project, :repository, :public, namespace: group) }
          let!(:project2) { create(:project, :repository, :public, namespace: group) }
          let!(:new_parent_group) { create(:group, :private) }

          it 'updates projects visibility to match the new parent' do
            group.projects.each do |project|
              expect(project.private?).to be_truthy
            end
          end

          it 'invokes #update_project_settings' do
            expect(transfer_service).to have_received(:update_project_settings)
                                          .with(group.projects.pluck(:id))
          end

          it_behaves_like 'project namespace path is in sync with project path' do
            let(:group_full_path) { "#{new_parent_group.path}/#{group.path}" }
            let(:projects_with_project_namespace) { [project1, project2] }
          end
        end
      end

      context 'when transferring a group with subgroups & projects descendants' do
        let!(:project1) { create(:project, :repository, :private, namespace: group) }
        let!(:project2) { create(:project, :repository, :internal, namespace: group) }
        let!(:subgroup1) { create(:group, :private, parent: group) }
        let!(:subgroup2) { create(:group, :internal, parent: group) }

        before do
          TestEnv.clean_test_path
          create(:group_member, :owner, group: new_parent_group, user: user)
          transfer_service.execute(new_parent_group)
        end

        it 'updates subgroups path' do
          new_parent_path = new_parent_group.path
          group.children.each do |subgroup|
            expect(subgroup.full_path).to eq("#{new_parent_path}/#{group.path}/#{subgroup.path}")
          end
        end

        it 'updates projects path' do
          new_parent_path = new_parent_group.path
          group.projects.each do |project|
            expect(project.full_path).to eq("#{new_parent_path}/#{group.path}/#{project.path}")
          end
        end

        it 'creates redirect for the subgroups and projects' do
          expect(group.redirect_routes.count).to eq(1)
          expect(subgroup1.redirect_routes.count).to eq(1)
          expect(subgroup2.redirect_routes.count).to eq(1)
          expect(project1.redirect_routes.count).to eq(1)
          expect(project2.redirect_routes.count).to eq(1)
        end

        it_behaves_like 'project namespace path is in sync with project path' do
          let(:group_full_path) { "#{new_parent_group.path}/#{group.path}" }
          let(:projects_with_project_namespace) { [project1, project2] }
        end
      end

      context 'when transferring a group with nested groups and projects' do
        let(:subgroup1) { create(:group, :private, parent: group) }
        let!(:project1) { create(:project, :repository, :private, namespace: group) }
        let!(:nested_subgroup) { create(:group, :private, parent: subgroup1) }
        let!(:nested_project) { create(:project, :repository, :private, namespace: subgroup1) }

        before do
          TestEnv.clean_test_path
          create(:group_member, :owner, group: new_parent_group, user: user)
        end

        context 'updated paths' do
          let_it_be_with_reload(:group) { create(:group, :public) }

          before do
            transfer_service.execute(new_parent_group)
          end

          it 'updates subgroups path' do
            new_base_path = "#{new_parent_group.path}/#{group.path}"
            group.children.each do |children|
              expect(children.full_path).to eq("#{new_base_path}/#{children.path}")
            end

            new_base_path = "#{new_parent_group.path}/#{group.path}/#{subgroup1.path}"
            subgroup1.children.each do |children|
              expect(children.full_path).to eq("#{new_base_path}/#{children.path}")
            end
          end

          it 'updates projects path' do
            new_parent_path = "#{new_parent_group.path}/#{group.path}"
            subgroup1.projects.each do |project|
              project_full_path = "#{new_parent_path}/#{project.namespace.path}/#{project.path}"
              expect(project.full_path).to eq(project_full_path)
            end
          end

          it 'creates redirect for the subgroups and projects' do
            expect(group.redirect_routes.count).to eq(1)
            expect(project1.redirect_routes.count).to eq(1)
            expect(subgroup1.redirect_routes.count).to eq(1)
            expect(nested_subgroup.redirect_routes.count).to eq(1)
            expect(nested_project.redirect_routes.count).to eq(1)
          end
        end

        context 'resets project authorizations' do
          let_it_be(:old_parent_group) { create(:group) }
          let_it_be_with_refind(:group) { create(:group, :private, parent: old_parent_group) }
          let_it_be(:new_group_member) { create(:user) }
          let_it_be(:old_group_member) { create(:user) }
          let_it_be(:unique_subgroup_member) { create(:user) }
          let_it_be(:direct_project_member) { create(:user) }

          before do
            new_parent_group.add_maintainer(new_group_member)
            old_parent_group.add_maintainer(old_group_member)
            subgroup1.add_developer(unique_subgroup_member)
            nested_project.add_developer(direct_project_member)
            group.refresh_members_authorized_projects
            subgroup1.refresh_members_authorized_projects
          end

          it 'removes old project authorizations' do
            expect { transfer_service.execute(new_parent_group) }.to change {
              ProjectAuthorization.where(project_id: project1.id, user_id: old_group_member.id).size
            }.from(1).to(0)
          end

          it 'adds new project authorizations' do
            expect { transfer_service.execute(new_parent_group) }.to change {
              ProjectAuthorization.where(project_id: project1.id, user_id: new_group_member.id).size
            }.from(0).to(1)
          end

          it 'performs authorizations job' do
            expect(AuthorizedProjectUpdate::ProjectRecalculateWorker).to receive(:bulk_perform_async)

            transfer_service.execute(new_parent_group)
          end

          context 'for nested projects' do
            it 'removes old project authorizations' do
              expect { transfer_service.execute(new_parent_group) }.to change {
                ProjectAuthorization.where(project_id: nested_project.id, user_id: old_group_member.id).size
              }.from(1).to(0)
            end

            it 'adds new project authorizations' do
              expect { transfer_service.execute(new_parent_group) }.to change {
                ProjectAuthorization.where(project_id: nested_project.id, user_id: new_group_member.id).size
              }.from(0).to(1)
            end

            it 'preserves existing project authorizations for direct project members' do
              expect { transfer_service.execute(new_parent_group) }.not_to change {
                ProjectAuthorization.where(project_id: nested_project.id, user_id: direct_project_member.id).count
              }
            end
          end

          context 'for nested groups with unique members' do
            it 'preserves existing project authorizations' do
              expect { transfer_service.execute(new_parent_group) }.not_to change {
                ProjectAuthorization.where(project_id: nested_project.id, user_id: unique_subgroup_member.id).count
              }
            end
          end

          context 'for groups with many projects' do
            let_it_be(:project_list) { create_list(:project, 11, :repository, :private, namespace: group) }

            it 'adds new project authorizations for the user which makes a transfer' do
              transfer_service.execute(new_parent_group)

              expect(ProjectAuthorization.where(project_id: project1.id, user_id: user.id).size).to eq(1)
              expect(ProjectAuthorization.where(project_id: nested_project.id, user_id: user.id).size).to eq(1)
            end

            it 'adds project authorizations for users in the new hierarchy' do
              expect { transfer_service.execute(new_parent_group) }.to change {
                ProjectAuthorization.where(project_id: project_list.map { |project| project.id }, user_id: new_group_member.id).size
              }.from(0).to(project_list.count)
            end

            it 'removes project authorizations for users in the old hierarchy' do
              expect { transfer_service.execute(new_parent_group) }.to change {
                ProjectAuthorization.where(project_id: project_list.map { |project| project.id }, user_id: old_group_member.id).size
              }.from(project_list.count).to(0)
            end

            it 'schedules authorizations job' do
              expect(AuthorizedProjectUpdate::ProjectRecalculateWorker).to receive(:bulk_perform_async)
                .with(array_including(group.all_projects.ids.map { |id| [id] }))

              transfer_service.execute(new_parent_group)
            end
          end

          context 'transferring groups with shared_projects' do
            let_it_be_with_reload(:shared_project) { create(:project, :public) }

            shared_examples_for 'drops the authorizations of ancestor members from the old hierarchy' do
              it 'drops the authorizations of ancestor members from the old hierarchy' do
                expect { transfer_service.execute(new_parent_group) }.to change {
                  ProjectAuthorization.where(project: shared_project, user: old_group_member).size
                }.from(1).to(0)
              end
            end

            context 'when the group that has existing project share is transferred' do
              before do
                create(:project_group_link, :maintainer, project: shared_project, group: group)
              end

              it_behaves_like 'drops the authorizations of ancestor members from the old hierarchy'
            end

            context 'when the group whose subgroup has an existing project share is transferred' do
              let_it_be_with_reload(:subgroup) { create(:group, :private, parent: group) }

              before do
                create(:project_group_link, :maintainer, project: shared_project, group: subgroup)
              end

              it_behaves_like 'drops the authorizations of ancestor members from the old hierarchy'
            end
          end

          context 'when a group that has existing group share is transferred' do
            let(:shared_with_group) { group }

            let_it_be(:member_of_shared_with_group) { create(:user) }
            let_it_be(:shared_group) { create(:group, :private) }
            let_it_be(:project_in_shared_group) { create(:project, namespace: shared_group) }

            before do
              shared_with_group.add_developer(member_of_shared_with_group)
              create(:group_group_link, :maintainer, shared_group: shared_group, shared_with_group: shared_with_group)
              shared_with_group.refresh_members_authorized_projects
            end

            it 'retains the authorizations of direct members' do
              expect { transfer_service.execute(new_parent_group) }.not_to change {
                ProjectAuthorization.where(
                  project: project_in_shared_group,
                  user: member_of_shared_with_group,
                  access_level: Gitlab::Access::DEVELOPER).size
              }.from(1)
            end
          end
        end
      end

      context 'when transferring a group with two factor authentication switched on' do
        before do
          TestEnv.clean_test_path
          create(:group_member, :owner, group: new_parent_group, user: user)
          create(:group, :private, parent: group, require_two_factor_authentication: true)
          group.update!(require_two_factor_authentication: true)
          new_parent_group.reload # make sure traversal_ids are reloaded
        end

        it 'does not update group two factor authentication setting' do
          transfer_service.execute(new_parent_group)

          expect(group.require_two_factor_authentication).to eq(true)
        end

        context 'when new parent disallows two factor authentication switched on for descendants' do
          before do
            new_parent_group.namespace_settings.update!(allow_mfa_for_subgroups: false)
          end

          it 'updates group two factor authentication setting' do
            transfer_service.execute(new_parent_group)

            expect(group.require_two_factor_authentication).to eq(false)
          end

          it 'schedules update of group two factor authentication setting for descendants' do
            expect(DisallowTwoFactorForSubgroupsWorker).to receive(:perform_async).with(group.id)

            transfer_service.execute(new_parent_group)
          end
        end
      end

      context 'when updating the group goes wrong' do
        let!(:subgroup1) { create(:group, :public, parent: group) }
        let!(:subgroup2) { create(:group, :public, parent: group) }
        let(:new_parent_group) { create(:group, :private) }
        let!(:project1) { create(:project, :repository, :public, namespace: group) }

        before do
          allow(group).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(group))
          TestEnv.clean_test_path
          create(:group_member, :owner, group: new_parent_group, user: user)
          transfer_service.execute(new_parent_group)
        end

        it 'restores group and projects visibility' do
          subgroup1.reload
          project1.reload
          expect(subgroup1.public?).to be_truthy
          expect(project1.public?).to be_truthy
        end
      end

      context 'when group has pending builds', :sidekiq_inline do
        let_it_be(:project) { create(:project, :public, namespace: group.reload) }
        let_it_be(:other_project) { create(:project) }
        let_it_be(:pending_build) { create(:ci_pending_build, project: project) }
        let_it_be(:unrelated_pending_build) { create(:ci_pending_build, project: other_project) }

        before do
          group.add_owner(user)
          new_parent_group.add_owner(user)
        end

        it 'updates pending builds for the group', :aggregate_failures do
          transfer_service.execute(new_parent_group)

          pending_build.reload
          unrelated_pending_build.reload

          expect(pending_build.namespace_id).to eq(group.id)
          expect(pending_build.namespace_traversal_ids).to eq(group.traversal_ids)
          expect(unrelated_pending_build.namespace_id).to eq(other_project.namespace_id)
          expect(unrelated_pending_build.namespace_traversal_ids).to eq(other_project.namespace.traversal_ids)
        end
      end
    end

    context 'when transferring a subgroup into root group' do
      let(:group) { create(:group, :public, :nested) }
      let(:subgroup) { create(:group, :public, parent: group) }
      let(:transfer_service) { described_class.new(subgroup, user) }

      it 'ensures there is still an owner for the transferred group' do
        expect(subgroup.all_owner_members).to be_empty

        transfer_service.execute(nil)
        subgroup.reload

        expect(subgroup.all_owner_members.map(&:user)).to match_array(user)
      end

      context 'when group has explicit owner' do
        let(:another_owner) { create(:user) }
        let!(:another_member) { create(:group_member, :owner, group: subgroup, user: another_owner) }

        it 'does not add additional owner' do
          expect(subgroup.all_owner_members.map(&:user)).to match_array(another_owner)

          transfer_service.execute(nil)
          subgroup.reload

          expect(subgroup.all_owner_members.map(&:user)).to match_array(another_owner)
        end
      end
    end

    context 'when a project has container images' do
      let(:group) { create(:group, :public, :nested) }
      let!(:container_repository) { create(:container_repository, project: project) }

      subject { transfer_service.execute(new_parent_group) }

      before do
        group.add_owner(user)
        new_parent_group.add_owner(user)
      end

      context 'within group' do
        let(:project) { create(:project, :repository, :public, namespace: group) }

        it 'does not transfer' do
          expect(subject).to be false
          expect(transfer_service.error).to match(/Docker images in their Container Registry/)
        end
      end

      context 'within subgroup' do
        let(:subgroup) { create(:group, parent: group) }
        let(:project) { create(:project, :repository, :public, namespace: subgroup) }

        it 'does not transfer' do
          expect(subject).to be false
          expect(transfer_service.error).to match(/Docker images in their Container Registry/)
        end
      end
    end

    context 'crm' do
      let(:root_group) { create(:group, :public) }
      let(:subgroup) { create(:group, :public, parent: root_group) }
      let(:another_subgroup) { create(:group, :public, parent: root_group) }
      let(:subsubgroup) { create(:group, :public, parent: subgroup) }

      let(:root_project) { create(:project, group: root_group) }
      let(:sub_project) { create(:project, group: subgroup) }
      let(:another_project) { create(:project, group: another_subgroup) }
      let(:subsub_project) { create(:project, group: subsubgroup) }

      let!(:contacts) { create_list(:contact, 4, group: root_group) }
      let!(:crm_organizations) { create_list(:crm_organization, 2, group: root_group) }

      before do
        create(:issue_customer_relations_contact, contact: contacts[0], issue: create(:issue, project: root_project))
        create(:issue_customer_relations_contact, contact: contacts[1], issue: create(:issue, project: sub_project))
        create(:issue_customer_relations_contact, contact: contacts[2], issue: create(:issue, project: another_project))
        create(:issue_customer_relations_contact, contact: contacts[3], issue: create(:issue, project: subsub_project))
        root_group.add_owner(user)
      end

      context 'moving up' do
        let(:group) { subsubgroup }

        it 'retains issue contacts' do
          expect { transfer_service.execute(root_group) }
            .not_to change { CustomerRelations::IssueContact.count }
        end

        it_behaves_like 'publishes a GroupTransferedEvent' do
          let(:target) { root_group }
        end
      end

      context 'moving down' do
        let(:group) { subgroup }

        it 'retains issue contacts' do
          expect { transfer_service.execute(another_subgroup) }
          .not_to change { CustomerRelations::IssueContact.count }
        end

        it_behaves_like 'publishes a GroupTransferedEvent' do
          let(:target) { another_subgroup }
        end
      end

      context 'moving sideways' do
        let(:group) { subsubgroup }

        it 'retains issue contacts' do
          expect { transfer_service.execute(another_subgroup) }
          .not_to change { CustomerRelations::IssueContact.count }
        end

        it_behaves_like 'publishes a GroupTransferedEvent' do
          let(:target) { another_subgroup }
        end
      end

      context 'moving to new root group' do
        let(:group) { root_group }

        before do
          new_parent_group.add_owner(user)
        end

        it 'moves all crm objects' do
          expect { transfer_service.execute(new_parent_group) }
            .to change { root_group.contacts.count }.by(-4)
            .and change { root_group.crm_organizations.count }.by(-2)
        end

        it 'retains issue contacts' do
          expect { transfer_service.execute(new_parent_group) }
            .not_to change { CustomerRelations::IssueContact.count }
        end

        it_behaves_like 'publishes a GroupTransferedEvent' do
          let(:target) { new_parent_group }
        end
      end

      context 'moving to a subgroup within a new root group' do
        let(:group) { root_group }
        let(:subgroup_in_new_parent_group) { create(:group, parent: new_parent_group) }

        context 'with permission on the root group' do
          before do
            new_parent_group.add_owner(user)
          end

          it 'moves all crm objects' do
            expect { transfer_service.execute(subgroup_in_new_parent_group) }
              .to change { root_group.contacts.count }.by(-4)
              .and change { root_group.crm_organizations.count }.by(-2)
          end

          it 'retains issue contacts' do
            expect { transfer_service.execute(subgroup_in_new_parent_group) }
              .not_to change { CustomerRelations::IssueContact.count }
          end

          it_behaves_like 'publishes a GroupTransferedEvent' do
            let(:target) { subgroup_in_new_parent_group }
          end
        end

        context 'with permission on the subgroup' do
          before do
            subgroup_in_new_parent_group.add_owner(user)
          end

          it 'raises error' do
            transfer_service.execute(subgroup_in_new_parent_group)

            expect(transfer_service.error).to eq("Transfer failed: Group contains contacts/organizations and you don't have enough permissions to move them to the new root group.")
          end

          it 'does not publish a GroupTransferedEvent' do
            expect { transfer_service.execute(subgroup_in_new_parent_group) }
              .not_to publish_event(Groups::GroupTransferedEvent)
          end
        end
      end
    end

    context 'with namespace_commit_emails concerns' do
      let_it_be(:group, reload: true) { create(:group) }
      let_it_be(:target) { create(:group) }

      before do
        group.add_owner(user)
        target.add_owner(user)
      end

      context 'when origin is a root group' do
        before do
          create_list(:namespace_commit_email, 2, namespace: group)
        end

        it 'deletes all namespace_commit_emails' do
          expect { transfer_service.execute(target) }
            .to change { group.namespace_commit_emails.count }.by(-2)
        end

        it_behaves_like 'publishes a GroupTransferedEvent'
      end

      context 'when origin is not a root group' do
        let(:group) { create(:group, parent: create(:group)) }

        it 'does not attempt to delete namespace_commit_emails' do
          expect(Users::NamespaceCommitEmail).not_to receive(:delete_for_namespace)

          transfer_service.execute(target)
        end
      end
    end
  end
end
