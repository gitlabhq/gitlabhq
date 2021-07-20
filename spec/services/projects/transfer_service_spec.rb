# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::TransferService do
  include GitHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:group_integration) { create(:integrations_slack, group: group, project: nil, webhook: 'http://group.slack.com') }

  let(:project) { create(:project, :repository, :legacy_storage, namespace: user.namespace) }

  subject(:execute_transfer) { described_class.new(project, user).execute(group).tap { project.reload } }

  context 'with npm packages' do
    before do
      group.add_owner(user)
    end

    subject(:transfer_service) { described_class.new(project, user) }

    let!(:package) { create(:npm_package, project: project) }

    context 'with a root namespace change' do
      it 'does not allow the transfer' do
        expect(transfer_service.execute(group)).to be false
        expect(project.errors[:new_namespace]).to include("Root namespace can't be updated if project has NPM packages")
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

      it 'does allow the transfer' do
        expect(transfer_service.execute(other_group)).to be true
        expect(project.errors[:new_namespace]).to be_empty
      end
    end
  end

  context 'namespace -> namespace' do
    before do
      allow_next_instance_of(Gitlab::UploadsTransfer) do |service|
        allow(service).to receive(:move_project).and_return(true)
      end
      allow_next_instance_of(Gitlab::PagesTransfer) do |service|
        allow(service).to receive(:move_project).and_return(true)
      end

      group.add_owner(user)
    end

    it 'updates the namespace' do
      transfer_result = execute_transfer

      expect(transfer_result).to be_truthy
      expect(project.namespace).to eq(group)
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

    it 'updates project full path in .git/config' do
      execute_transfer

      expect(rugged_config['gitlab.fullpath']).to eq "#{group.full_path}/#{project.path}"
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
      let_it_be(:instance_integration) { create(:integrations_slack, :instance, webhook: 'http://project.slack.com') }

      context 'with an inherited integration' do
        let_it_be(:project_integration) { create(:integrations_slack, project: project, webhook: 'http://project.slack.com', inherit_from_id: instance_integration.id) }

        it 'replaces inherited integrations', :aggregate_failures do
          execute_transfer

          expect(project.slack_integration.webhook).to eq(group_integration.webhook)
          expect(Integration.count).to eq(3)
        end
      end

      context 'with a custom integration' do
        let_it_be(:project_integration) { create(:integrations_slack, project: project, webhook: 'http://project.slack.com') }

        it 'does not updates the integrations' do
          expect { execute_transfer }.not_to change { project.slack_integration.webhook }
        end
      end
    end
  end

  context 'when transfer fails' do
    let!(:original_path) { project_path(project) }

    def attempt_project_transfer(&block)
      expect do
        execute_transfer
      end.to raise_error(ActiveRecord::ActiveRecordError)
    end

    before do
      group.add_owner(user)

      expect_any_instance_of(Labels::TransferService).to receive(:execute).and_raise(ActiveRecord::StatementInvalid, "PG ERROR")
    end

    def project_path(project)
      Gitlab::GitalyClient::StorageSettings.allow_disk_access do
        project.repository.path_to_repo
      end
    end

    def current_path
      project_path(project)
    end

    it 'rolls back repo location' do
      attempt_project_transfer

      expect(project.repository.raw.exists?).to be(true)
      expect(original_path).to eq current_path
    end

    it 'rolls back project full path in .git/config' do
      attempt_project_transfer

      expect(rugged_config['gitlab.fullpath']).to eq project.full_path
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
  end

  context 'namespace -> no namespace' do
    let(:group) { nil }

    it 'does not allow the project transfer' do
      transfer_result = execute_transfer

      expect(transfer_result).to eq false
      expect(project.namespace).to eq(user.namespace)
      expect(project.errors.messages[:new_namespace].first).to eq 'Please select a new namespace for your project.'
    end
  end

  context 'disallow transferring of project with tags' do
    let(:container_repository) { create(:container_repository) }

    before do
      stub_container_registry_config(enabled: true)
      stub_container_registry_tags(repository: :any, tags: ['tag'])
      project.container_repositories << container_repository
    end

    it 'does not allow the project transfer' do
      expect(execute_transfer).to eq false
    end
  end

  context 'namespace -> not allowed namespace' do
    it 'does not allow the project transfer' do
      transfer_result = execute_transfer

      expect(transfer_result).to eq false
      expect(project.namespace).to eq(user.namespace)
    end
  end

  context 'namespace which contains orphan repository with same projects path name' do
    let(:fake_repo_path) { File.join(TestEnv.repos_path, group.full_path, "#{project.path}.git") }

    before do
      group.add_owner(user)

      TestEnv.create_bare_repository(fake_repo_path)
    end

    after do
      FileUtils.rm_rf(fake_repo_path)
    end

    it 'does not allow the project transfer' do
      transfer_result = execute_transfer

      expect(transfer_result).to eq false
      expect(project.namespace).to eq(user.namespace)
      expect(project.errors[:new_namespace]).to include('Cannot move project')
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

  context 'target namespace allows developers to create projects' do
    let(:group) { create(:group, project_creation_level: ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS) }

    context 'the user is a member of the target namespace with developer permissions' do
      before do
        group.add_developer(user)
      end

      it 'does not allow project transfer to the target namespace' do
        transfer_result = execute_transfer

        expect(transfer_result).to eq false
        expect(project.namespace).to eq(user.namespace)
        expect(project.errors[:new_namespace]).to include('Transfer failed, please contact an admin.')
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
      true  | 'disabled_and_unoverridable' | false
      false | 'disabled_and_unoverridable' | false
      true  | 'disabled_with_override'     | true
      false | 'disabled_with_override'     | false
      true  | 'enabled'                    | true
      false | 'enabled'                    | false
    end

    with_them do
      let(:project) { create(:project, :public, :repository, namespace: user.namespace, shared_runners_enabled: project_shared_runners_enabled) }
      let(:group) { create(:group) }

      before do
        group.add_owner(user)
        expect_next_found_instance_of(Group) do |group|
          expect(group).to receive(:shared_runners_setting).and_return(shared_runners_setting)
        end

        execute_transfer
      end

      it 'updates shared runners based on the parent group' do
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

    context 'when the feature flag `specialized_worker_for_project_transfer_auth_recalculation` is enabled' do
      before do
        stub_feature_flags(specialized_worker_for_project_transfer_auth_recalculation: true)
      end

      it 'calls AuthorizedProjectUpdate::ProjectRecalculateWorker to update project authorizations' do
        expect(AuthorizedProjectUpdate::ProjectRecalculateWorker)
          .to receive(:perform_async).with(project.id)

        execute_transfer
      end

      it 'calls AuthorizedProjectUpdate::UserRefreshFromReplicaWorker with a delay to update project authorizations' do
        user_ids = [user.id, member_of_old_group.id, member_of_new_group.id].map { |id| [id] }

        expect(AuthorizedProjectUpdate::UserRefreshFromReplicaWorker).to(
          receive(:bulk_perform_in)
            .with(1.hour,
                  user_ids,
                  batch_delay: 30.seconds, batch_size: 100)
        )

        subject
      end

      it 'refreshes the permissions of the members of the old and new namespace', :sidekiq_inline do
        expect { execute_transfer }
          .to change { member_of_old_group.authorized_projects.include?(project) }.from(true).to(false)
          .and change { member_of_new_group.authorized_projects.include?(project) }.from(false).to(true)
      end
    end

    context 'when the feature flag `specialized_worker_for_project_transfer_auth_recalculation` is disabled' do
      before do
        stub_feature_flags(specialized_worker_for_project_transfer_auth_recalculation: false)
      end

      it 'calls UserProjectAccessChangedService to update project authorizations' do
        user_ids = [user.id, member_of_old_group.id, member_of_new_group.id]

        expect_next_instance_of(UserProjectAccessChangedService, user_ids) do |service|
          expect(service).to receive(:execute)
        end

        execute_transfer
      end

      it 'refreshes the permissions of the members of the old and new namespace' do
        expect { execute_transfer }
          .to change { member_of_old_group.authorized_projects.include?(project) }.from(true).to(false)
          .and change { member_of_new_group.authorized_projects.include?(project) }.from(false).to(true)
      end
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

    it 'does not create a design repository' do
      expect(subject.execute(group)).to be true

      project.clear_memoization(:design_repository)

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

          project.clear_memoization(:design_repository)

          expect(design_repository).to have_attributes(
            disk_path: new_full_path,
            full_path: new_full_path
          )
        end

        it 'does not move the repository when an error occurs', :aggregate_failures do
          allow(subject).to receive(:execute_system_hooks).and_raise('foo')
          expect { subject.execute(group) }.to raise_error('foo')

          project.clear_memoization(:design_repository)

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

          project.clear_memoization(:design_repository)

          expect(design_repository).to have_attributes(
            disk_path: old_disk_path,
            full_path: new_full_path
          )
        end

        it 'does not move the repository when an error occurs' do
          old_disk_path = design_repository.disk_path

          allow(subject).to receive(:execute_system_hooks).and_raise('foo')
          expect { subject.execute(group) }.to raise_error('foo')

          project.clear_memoization(:design_repository)

          expect(design_repository).to have_attributes(
            disk_path: old_disk_path,
            full_path: old_full_path
          )
        end
      end
    end
  end

  context 'moving pages' do
    let_it_be(:project) { create(:project, namespace: user.namespace) }

    before do
      group.add_owner(user)
    end

    it 'schedules a job when pages are deployed' do
      project.mark_pages_as_deployed

      expect(PagesTransferWorker).to receive(:perform_async)
                                       .with("move_project", [project.path, user.namespace.full_path, group.full_path])

      execute_transfer
    end

    it 'does not schedule a job when no pages are deployed' do
      expect(PagesTransferWorker).not_to receive(:perform_async)

      execute_transfer
    end
  end

  def rugged_config
    rugged_repo(project.repository).config
  end
end
