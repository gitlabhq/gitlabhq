# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::TransferService, feature_category: :groups_and_projects do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:group_integration) { create(:integrations_slack, :group, group: group, webhook: 'http://group.slack.com') }

  let(:project) { create(:project, :repository, :legacy_storage, namespace: user.namespace) }
  let(:target) { group }
  let(:executor) { user }

  subject(:execute_transfer) { described_class.new(project, executor).execute(target).tap { project.reload } }

  before do
    allow(project).to receive(:has_container_registry_tags?).and_return(false)
  end

  context 'with npm packages' do
    before do
      group.add_owner(user)
    end

    subject(:transfer_service) { described_class.new(project, user) }

    let!(:package) { create(:npm_package, project: project, name: "@testscope/test") }

    shared_examples 'allow the transfer' do
      it 'allows the transfer' do
        expect(transfer_service.execute(namespace)).to be true
        expect(project.errors[:new_namespace]).to be_empty
      end
    end

    context 'with a root namespace change' do
      it_behaves_like 'allow the transfer' do
        let(:namespace) { group }
      end
    end

    context 'with pending destruction package' do
      before do
        package.pending_destruction!
      end

      it_behaves_like 'allow the transfer' do
        let(:namespace) { group }
      end
    end

    context 'with namespaced packages present' do
      let!(:package) { create(:npm_package, project: project, name: "@#{project.root_namespace.path}/test") }

      it 'does not allow the transfer' do
        expect(transfer_service.execute(group)).to be false
        expect(project.errors[:new_namespace]).to include("Root namespace can't be updated if the project has NPM packages scoped to the current root level namespace.")
      end
    end

    context 'without a root namespace change' do
      let(:root) { create(:group) }
      let(:group) { create(:group, parent: root) }
      let(:other_group) { create(:group, parent: root) }
      let(:project) { create(:project, :repository, namespace: group) }

      before do
        other_group.add_owner(user)
      end

      it_behaves_like 'allow the transfer' do
        let(:namespace) { other_group }
      end
    end
  end

  context 'namespace -> namespace' do
    before do
      allow_next_instance_of(Gitlab::UploadsTransfer) do |service|
        allow(service).to receive(:move_project).and_return(true)
      end

      group.add_owner(user)
    end

    it 'updates the namespace' do
      transfer_result = execute_transfer

      expect(transfer_result).to be_truthy
      expect(project.namespace).to eq(group)
    end

    context 'EventStore' do
      let(:group) do
        create(:group, :nested, owners: user)
      end

      let(:target) do
        create(:group, :nested, owners: user)
      end

      let(:project) { create(:project, namespace: group) }

      it 'publishes a ProjectTransferedEvent' do
        expect { execute_transfer }
          .to publish_event(Projects::ProjectTransferedEvent)
          .with(
            project_id: project.id,
            old_namespace_id: group.id,
            old_root_namespace_id: group.root_ancestor.id,
            new_namespace_id: target.id,
            new_root_namespace_id: target.root_ancestor.id
          )
      end
    end

    context 'when project has an associated project namespace' do
      it 'keeps project namespace in sync with project' do
        transfer_result = execute_transfer

        expect(transfer_result).to be_truthy

        project_namespace_in_sync(group)
      end

      context 'when project is transferred to a deeper nested group' do
        let(:parent_group) { create(:group) }
        let(:sub_group) { create(:group, parent: parent_group) }
        let(:sub_sub_group) { create(:group, parent: sub_group) }
        let(:group) { sub_sub_group }

        it 'keeps project namespace in sync with project' do
          transfer_result = execute_transfer

          expect(transfer_result).to be_truthy

          project_namespace_in_sync(sub_sub_group)
        end
      end
    end
  end

  context 'project in a group -> a personal namespace', :enable_admin_mode do
    let(:project) { create(:project, :repository, :legacy_storage, group: group) }
    let(:target) { user.namespace }
    # We need to use an admin user as the executor because
    # only an admin user has required permissions to transfer projects
    # under _all_ the different circumstances specified below.
    let(:executor) { create(:user, :admin) }

    it 'executes the transfer to personal namespace successfully' do
      execute_transfer

      expect(project.namespace).to eq(user.namespace)
    end

    it 'invalidates personal_project_count cache of the the owner of the personal namespace' do
      expect(user).to receive(:invalidate_personal_projects_count)

      execute_transfer
    end

    context 'the owner of the namespace does not have a direct membership in the project residing in the group' do
      it 'creates a project membership record for the owner of the namespace, with OWNER access level, after the transfer' do
        execute_transfer

        expect(project.members.owners.find_by(user_id: user.id)).to be_present
      end
    end

    context 'the owner of the namespace has a direct membership in the project residing in the group' do
      context 'that membership has an access level of OWNER' do
        before do
          project.add_owner(user)
        end

        it 'retains the project membership record for the owner of the namespace, with OWNER access level, after the transfer' do
          execute_transfer

          expect(project.members.owners.find_by(user_id: user.id)).to be_present
        end
      end

      context 'that membership has an access level that is not OWNER' do
        before do
          project.add_developer(user)
        end

        it 'updates the project membership record for the owner of the namespace, to OWNER access level, after the transfer' do
          execute_transfer

          expect(project.members.owners.find_by(user_id: user.id)).to be_present
        end
      end
    end
  end

  context 'personal namespace -> group', :enable_admin_mode do
    let(:executor) { create(:admin) }

    it 'invalidates personal_project_count cache of the the owner of the personal namespace' \
       'that previously held the project' do
      expect(user).to receive(:invalidate_personal_projects_count)

      execute_transfer
    end
  end

  context 'when transfer succeeds' do
    before do
      group.add_owner(user)
    end

    it 'sends notifications' do
      expect_any_instance_of(NotificationService).to receive(:project_was_moved)

      execute_transfer
    end

    it 'invalidates the user\'s personal_project_count cache' do
      expect(user).to receive(:invalidate_personal_projects_count)

      execute_transfer
    end

    it 'executes system hooks' do
      expect_next_instance_of(described_class) do |service|
        expect(service).to receive(:execute_system_hooks)
      end

      execute_transfer
    end

    it 'moves the disk path', :aggregate_failures do
      old_path = project.repository.disk_path
      old_full_path = project.repository.full_path

      execute_transfer

      project.reload_repository!

      expect(project.repository.disk_path).not_to eq(old_path)
      expect(project.repository.full_path).not_to eq(old_full_path)
      expect(project.disk_path).not_to eq(old_path)
      expect(project.disk_path).to start_with(group.path)
    end

    it 'updates project full path in gitaly' do
      execute_transfer

      expect(project.repository.full_path).to eq "#{group.full_path}/#{project.path}"
    end

    it 'updates storage location' do
      execute_transfer

      expect(project.project_repository).to have_attributes(
        disk_path: "#{group.full_path}/#{project.path}",
        shard_name: project.repository_storage
      )
    end

    context 'with a project integration' do
      let_it_be_with_reload(:project) { create(:project, namespace: user.namespace) }
      let_it_be(:instance_integration) { create(:integrations_slack, :instance) }
      let_it_be(:project_integration) { create(:integrations_slack, project: project) }

      context 'when it inherits from instance_integration' do
        before do
          project_integration.update!(inherit_from_id: instance_integration.id, webhook: instance_integration.webhook)
        end

        it 'replaces inherited integrations', :aggregate_failures do
          expect { execute_transfer }
            .to change(Integration, :count).by(0)
            .and change { project.slack_integration.webhook }.to eq(group_integration.webhook)
        end
      end

      context 'with a custom integration' do
        it 'does not update the integrations' do
          expect { execute_transfer }.not_to change { project.slack_integration.webhook }
        end
      end

      context 'when the new default integration is instance specific and deactivated' do
        let!(:instance_specific_integration) { create(:beyond_identity_integration) }
        let!(:project_instance_specific_integration) do
          create(
            :beyond_identity_integration,
            project: project,
            instance: false,
            active: true,
            inherit_from_id: instance_specific_integration.id
          )
        end

        let!(:group_instance_specific_integration) do
          create(:beyond_identity_integration, group: target, instance: false, active: false)
        end

        it 'creates an integration inheriting from the default' do
          expect { execute_transfer }
            .to change { project.beyond_identity_integration.reload.active }.from(true).to(false)
            .and change { project.beyond_identity_integration.inherit_from_id }.to(group_instance_specific_integration.id)
        end
      end
    end

    context 'when project has pending builds', :sidekiq_inline do
      let!(:other_project) { create(:project) }
      let!(:pending_build) { create(:ci_pending_build, project: project.reload) }
      let!(:unrelated_pending_build) { create(:ci_pending_build, project: other_project) }

      before do
        group.reload
      end

      it 'updates pending builds for the project', :aggregate_failures do
        execute_transfer

        pending_build.reload
        unrelated_pending_build.reload

        expect(pending_build.namespace_id).to eq(group.id)
        expect(pending_build.namespace_traversal_ids).to eq(group.traversal_ids)
        expect(unrelated_pending_build.namespace_id).to eq(other_project.namespace_id)
        expect(unrelated_pending_build.namespace_traversal_ids).to eq(other_project.namespace.traversal_ids)
      end
    end
  end

  context 'when transfer fails' do
    let!(:original_path) { project.repository.relative_path }

    def attempt_project_transfer(&block)
      expect do
        execute_transfer
      end.to raise_error(ActiveRecord::ActiveRecordError)
    end

    before do
      group.add_owner(user)

      expect_any_instance_of(Labels::TransferService).to receive(:execute).and_raise(ActiveRecord::StatementInvalid, "PG ERROR")
    end

    it 'rolls back repo location' do
      attempt_project_transfer

      expect(project.repository.raw.exists?).to be(true)
      expect(original_path).to eq project.repository.relative_path
    end

    it 'rolls back project full path in gitaly' do
      attempt_project_transfer

      expect(project.repository.full_path).to eq project.full_path
    end

    it "doesn't send move notifications" do
      expect_any_instance_of(NotificationService).not_to receive(:project_was_moved)

      attempt_project_transfer
    end

    it "doesn't run system hooks" do
      attempt_project_transfer do |service|
        expect(service).not_to receive(:execute_system_hooks)
      end
    end

    it 'does not update storage location' do
      attempt_project_transfer

      expect(project.project_repository).to have_attributes(
        disk_path: project.disk_path,
        shard_name: project.repository_storage
      )
    end

    it 'does not publish a ProjectTransferedEvent' do
      expect { attempt_project_transfer }
        .not_to publish_event(Projects::ProjectTransferedEvent)
    end

    context 'when project has pending builds', :sidekiq_inline do
      let!(:other_project) { create(:project) }
      let!(:pending_build) { create(:ci_pending_build, project: project.reload) }
      let!(:unrelated_pending_build) { create(:ci_pending_build, project: other_project) }

      it 'does not update pending builds for the project', :aggregate_failures do
        attempt_project_transfer

        pending_build.reload
        unrelated_pending_build.reload

        expect(pending_build.namespace_id).to eq(project.namespace_id)
        expect(pending_build.namespace_traversal_ids).to eq(project.namespace.traversal_ids)
        expect(unrelated_pending_build.namespace_id).to eq(other_project.namespace_id)
        expect(unrelated_pending_build.namespace_traversal_ids).to eq(other_project.namespace.traversal_ids)
      end
    end

    context 'when project has an associated project namespace' do
      it 'keeps project namespace in sync with project' do
        attempt_project_transfer

        project_namespace_in_sync(user.namespace)
      end
    end
  end

  context 'namespace -> no namespace' do
    let(:group) { nil }

    it 'does not allow the project transfer' do
      transfer_result = execute_transfer

      expect(transfer_result).to eq false
      expect(project.namespace).to eq(user.namespace)
      expect(project.errors.messages[:new_namespace].first).to eq 'Please select a new namespace for your project.'
    end

    context 'when project has an associated project namespace' do
      it 'keeps project namespace in sync with project' do
        transfer_result = execute_transfer

        expect(transfer_result).to be false

        project_namespace_in_sync(user.namespace)
      end
    end
  end

  context 'when the project has registry tags' do
    let_it_be_with_reload(:project) { create(:project, :repository, :legacy_storage, namespace: group) }
    let(:target) { create(:group, parent: group) }

    before do
      group.add_owner(user)
      allow(project).to receive(:has_container_registry_tags?).and_return(true)
    end

    shared_examples 'project transfer failed with a message' do |message|
      it 'fails with an error message' do
        expect(execute_transfer).to eq false
        expect(project.errors[:new_namespace]).to include(message)
      end
    end

    context 'when the GitLab API is supported' do
      let(:dry_run_result) { :accepted }

      before do
        allow(ContainerRegistry::GitlabApiClient).to receive_messages(supports_gitlab_api?: true, move_repository_to_namespace: dry_run_result)
      end

      context 'when transferring within the same top level namespace' do
        context 'when the dry run in the registry succeeds' do
          it 'allows the transfer to continue' do
            expect(ContainerRegistry::GitlabApiClient).to receive(:move_repository_to_namespace).with(
              project.full_path, namespace: target.full_path, dry_run: true)

            expect(execute_transfer).to eq true
          end
        end

        context 'when the dry run in the registry fails' do
          let(:dry_run_result) { :bad_request }

          before do
            expect(ContainerRegistry::GitlabApiClient)
              .to receive(:move_repository_to_namespace)
              .with(project.full_path, namespace: target.full_path, dry_run: true)
              .and_return(dry_run_result)
          end

          it_behaves_like 'project transfer failed with a message', 'Project cannot be transferred because of a container registry error: Bad Request'
        end
      end

      context 'when transferring to a different top level namespace' do
        let(:target) { create(:group) }

        before do
          target.add_owner(user)
        end

        it_behaves_like 'project transfer failed with a message', 'Project cannot be transferred to a different top-level namespace, because image tags are present in its container registry'
      end
    end

    context 'when the GitLab API is not supported' do
      before do
        allow(ContainerRegistry::GitlabApiClient).to receive(:supports_gitlab_api?).and_return(false)
      end

      it_behaves_like 'project transfer failed with a message', 'Project cannot be transferred, because image tags are present in its container registry'
    end
  end

  context 'namespace -> not allowed namespace' do
    it 'does not allow the project transfer' do
      transfer_result = execute_transfer

      expect(transfer_result).to eq false
      expect(project.namespace).to eq(user.namespace)
    end
  end

  context 'target namespace containing the same project name' do
    before do
      group.add_owner(user)
      create(:project, name: project.name, group: group, path: 'other')
    end

    it 'does not allow the project transfer' do
      transfer_result = execute_transfer

      expect(transfer_result).to eq false
      expect(project.namespace).to eq(user.namespace)
      expect(project.errors[:new_namespace]).to include('Project with same name or path in target namespace already exists')
    end
  end

  context 'target namespace containing the same project path' do
    before do
      group.add_owner(user)
      create(:project, name: 'other-name', path: project.path, group: group)
    end

    it 'does not allow the project transfer' do
      transfer_result = execute_transfer

      expect(transfer_result).to eq false
      expect(project.namespace).to eq(user.namespace)
      expect(project.errors[:new_namespace]).to include('Project with same name or path in target namespace already exists')
    end
  end

  context 'target namespace matches current namespace' do
    let(:group) { user.namespace }

    it 'does not allow project transfer' do
      transfer_result = execute_transfer

      expect(transfer_result).to eq false
      expect(project.namespace).to eq(user.namespace)
      expect(project.errors[:new_namespace]).to include('Project is already in this namespace.')
    end
  end

  context 'target namespace belongs to bot user', :enable_admin_mode do
    let(:bot) { create(:user, :project_bot) }
    let(:target) { bot.namespace }
    let(:executor) { create(:user, :admin) }

    it 'does not allow project transfer' do
      namespace = project.namespace

      transfer_result = execute_transfer

      expect(transfer_result).to eq false
      expect(project.namespace).to eq(namespace)
      expect(project.errors[:new_namespace]).to include("You don't have permission to transfer projects into that namespace.")
    end
  end

  context 'when user does not own the project' do
    let(:project) { create(:project, :repository, :legacy_storage) }

    before do
      project.add_developer(user)
    end

    it 'does not allow project transfer to the target namespace' do
      transfer_result = execute_transfer

      expect(transfer_result).to eq false
      expect(project.errors[:new_namespace]).to include("You don't have permission to transfer this project.")
    end
  end

  context 'when user can create projects in the target namespace' do
    let(:group) { create(:group, project_creation_level: ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS) }

    context 'but has only developer permissions in the target namespace' do
      before do
        group.add_developer(user)
      end

      it 'does not allow project transfer to the target namespace' do
        transfer_result = execute_transfer

        expect(transfer_result).to eq false
        expect(project.namespace).to eq(user.namespace)
        expect(project.errors[:new_namespace]).to include("You don't have permission to transfer projects into that namespace.")
      end
    end
  end

  context 'visibility level' do
    let(:group) { create(:group, :internal) }

    before do
      group.add_owner(user)
    end

    context 'when namespace visibility level < project visibility level' do
      let(:project) { create(:project, :public, :repository, namespace: user.namespace) }

      before do
        execute_transfer
      end

      it { expect(project.visibility_level).to eq(group.visibility_level) }
    end

    context 'when namespace visibility level > project visibility level' do
      let(:project) { create(:project, :private, :repository, namespace: user.namespace) }

      before do
        execute_transfer
      end

      it { expect(project.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE) }
    end
  end

  context 'shared Runners group level configurations' do
    using RSpec::Parameterized::TableSyntax

    where(:project_shared_runners_enabled, :shared_runners_setting, :expected_shared_runners_enabled) do
      true  | :shared_runners_disabled_and_unoverridable | false
      false | :shared_runners_disabled_and_unoverridable | false
      true  | :shared_runners_disabled_and_overridable   | true
      false | :shared_runners_disabled_and_overridable   | false
      true  | :shared_runners_enabled                    | true
      false | :shared_runners_enabled                    | false
    end

    with_them do
      let(:project) { create(:project, :public, :repository, namespace: user.namespace, shared_runners_enabled: project_shared_runners_enabled) }
      let(:group) { create(:group, shared_runners_setting) }

      it 'updates shared runners based on the parent group' do
        group.add_owner(user)

        expect(execute_transfer).to eq(true)

        expect(project.shared_runners_enabled).to eq(expected_shared_runners_enabled)
      end
    end
  end

  context 'missing group labels applied to issues or merge requests' do
    it 'delegates transfer to Labels::TransferService' do
      group.add_owner(user)

      expect_next_instance_of(Labels::TransferService, user, project.group, project) do |labels_transfer_service|
        expect(labels_transfer_service).to receive(:execute).once.and_call_original
      end

      execute_transfer
    end
  end

  context 'missing group milestones applied to issues or merge requests' do
    it 'delegates transfer to Milestones::TransferService' do
      group.add_owner(user)

      expect_next_instance_of(Milestones::TransferService, user, project.group, project) do |milestones_transfer_service|
        expect(milestones_transfer_service).to receive(:execute).once.and_call_original
      end

      execute_transfer
    end
  end

  context 'when hashed storage in use' do
    let!(:project) { create(:project, :repository, namespace: user.namespace) }
    let!(:old_disk_path) { project.repository.disk_path }

    before do
      group.add_owner(user)
    end

    it 'does not move the disk path', :aggregate_failures do
      new_full_path = "#{group.full_path}/#{project.path}"

      execute_transfer

      project.reload_repository!

      expect(project.repository).to have_attributes(
        disk_path: old_disk_path,
        full_path: new_full_path
      )
      expect(project.disk_path).to eq(old_disk_path)
    end

    it 'does not move the disk path when the transfer fails', :aggregate_failures do
      old_full_path = project.full_path

      expect_next_instance_of(described_class) do |service|
        allow(service).to receive(:execute_system_hooks).and_raise('foo')
      end

      expect { execute_transfer }.to raise_error('foo')

      project.reload_repository!

      expect(project.repository).to have_attributes(
        disk_path: old_disk_path,
        full_path: old_full_path
      )
      expect(project.disk_path).to eq(old_disk_path)
    end
  end

  describe 'refreshing project authorizations' do
    let(:old_group) { create(:group) }
    let!(:project) { create(:project, namespace: old_group) }
    let(:member_of_old_group) { create(:user) }
    let(:group) { create(:group) }
    let(:member_of_new_group) { create(:user) }

    before do
      old_group.add_developer(member_of_old_group)
      group.add_maintainer(member_of_new_group)

      # Add the executing user as owner in both groups, so that
      # transfer can be executed.
      old_group.add_owner(user)
      group.add_owner(user)
    end

    it 'calls AuthorizedProjectUpdate::ProjectRecalculateWorker to update project authorizations' do
      expect(AuthorizedProjectUpdate::ProjectRecalculateWorker)
        .to receive(:perform_async).with(project.id)

      execute_transfer
    end

    it 'calls AuthorizedProjectUpdate::UserRefreshFromReplicaWorker with a delay to update project authorizations' do
      stub_feature_flags(do_not_run_safety_net_auth_refresh_jobs: false)

      user_ids = [user.id, member_of_old_group.id, member_of_new_group.id].map { |id| [id] }

      expect(AuthorizedProjectUpdate::UserRefreshFromReplicaWorker).to(
        receive(:bulk_perform_in).with(
          1.hour,
          user_ids,
          batch_delay: 30.seconds, batch_size: 100
        )
      )

      subject
    end

    it 'refreshes the permissions of the members of the old and new namespace', :sidekiq_inline do
      expect { execute_transfer }
        .to change { member_of_old_group.authorized_projects.include?(project) }.from(true).to(false)
        .and change { member_of_new_group.authorized_projects.include?(project) }.from(false).to(true)
    end
  end

  describe 'transferring a design repository' do
    subject { described_class.new(project, user) }

    before do
      group.add_owner(user)
    end

    def design_repository
      project.design_repository
    end

    def clear_design_repo_memoization
      project&.design_management_repository&.clear_memoization(:repository)
      project.clear_memoization(:design_repository)
    end

    it 'does not create a design repository' do
      expect(subject.execute(group)).to be true

      clear_design_repo_memoization

      expect(design_repository.exists?).to be false
    end

    describe 'when the project has a design repository' do
      let(:project_repo_path) { "#{project.path}#{::Gitlab::GlRepository::DESIGN.path_suffix}" }
      let(:old_full_path) { "#{user.namespace.full_path}/#{project_repo_path}" }
      let(:new_full_path) { "#{group.full_path}/#{project_repo_path}" }

      context 'with legacy storage' do
        let(:project) { create(:project, :repository, :legacy_storage, :design_repo, namespace: user.namespace) }

        it 'moves the repository' do
          expect(subject.execute(group)).to be true

          clear_design_repo_memoization

          expect(design_repository).to have_attributes(
            disk_path: new_full_path,
            full_path: new_full_path
          )
        end

        it 'does not move the repository when an error occurs', :aggregate_failures do
          allow(subject).to receive(:execute_system_hooks).and_raise('foo')
          expect { subject.execute(group) }.to raise_error('foo')

          clear_design_repo_memoization

          expect(design_repository).to have_attributes(
            disk_path: old_full_path,
            full_path: old_full_path
          )
        end
      end

      context 'with hashed storage' do
        let(:project) { create(:project, :repository, namespace: user.namespace) }

        it 'does not move the repository' do
          old_disk_path = design_repository.disk_path

          expect(subject.execute(group)).to be true

          clear_design_repo_memoization

          expect(design_repository).to have_attributes(
            disk_path: old_disk_path,
            full_path: new_full_path
          )
        end

        it 'does not move the repository when an error occurs' do
          old_disk_path = design_repository.disk_path

          allow(subject).to receive(:execute_system_hooks).and_raise('foo')
          expect { subject.execute(group) }.to raise_error('foo')

          clear_design_repo_memoization

          expect(design_repository).to have_attributes(
            disk_path: old_disk_path,
            full_path: old_full_path
          )
        end
      end
    end
  end

  context 'handling issue contacts' do
    let_it_be(:root_group) { create(:group) }

    let(:project) { create(:project, group: root_group) }

    before do
      root_group.add_owner(user)
      target.add_owner(user)
      create_list(:issue_customer_relations_contact, 2, :for_issue, issue: create(:issue, project: project))
    end

    context 'with the same root_ancestor' do
      let(:target) { create(:group, parent: root_group) }

      it 'retains issue contacts' do
        expect { execute_transfer }.not_to change { CustomerRelations::IssueContact.count }
      end
    end

    context 'with a different root_ancestor' do
      it 'deletes issue contacts' do
        expect { execute_transfer }.to change { CustomerRelations::IssueContact.count }.by(-2)
      end
    end
  end

  def project_namespace_in_sync(group)
    project.reload
    expect(project.namespace).to eq(group)
    expect(project.project_namespace.visibility_level).to eq(project.visibility_level)
    expect(project.project_namespace.path).to eq(project.path)
    expect(project.project_namespace.parent).to eq(project.namespace)
    expect(project.project_namespace.traversal_ids).to eq([*project.namespace.traversal_ids, project.project_namespace.id])
  end
end
