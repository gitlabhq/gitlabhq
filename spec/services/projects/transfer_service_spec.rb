require 'spec_helper'

describe Projects::TransferService do
  let(:gitlab_shell) { Gitlab::Shell.new }
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, :repository, :legacy_storage, namespace: user.namespace) }

  context 'namespace -> namespace' do
    before do
      allow_any_instance_of(Gitlab::UploadsTransfer)
        .to receive(:move_project).and_return(true)
      allow_any_instance_of(Gitlab::PagesTransfer)
        .to receive(:move_project).and_return(true)
      group.add_owner(user)
      @result = transfer_project(project, user, group)
    end

    it { expect(@result).to be_truthy }
    it { expect(project.namespace).to eq(group) }
  end

  context 'when transfer succeeds' do
    before do
      group.add_owner(user)
    end

    it 'sends notifications' do
      expect_any_instance_of(NotificationService).to receive(:project_was_moved)

      transfer_project(project, user, group)
    end

    it 'expires full_path cache' do
      expect(project).to receive(:expires_full_path_cache)

      transfer_project(project, user, group)
    end

    it 'executes system hooks' do
      transfer_project(project, user, group) do |service|
        expect(service).to receive(:execute_system_hooks)
      end
    end

    it 'disk path has moved' do
      old_path = project.repository.disk_path
      old_full_path = project.repository.full_path

      transfer_project(project, user, group)

      expect(project.repository.disk_path).not_to eq(old_path)
      expect(project.repository.full_path).not_to eq(old_full_path)
      expect(project.disk_path).not_to eq(old_path)
      expect(project.disk_path).to start_with(group.path)
    end

    it 'updates project full path in .git/config' do
      transfer_project(project, user, group)

      expect(project.repository.rugged.config['gitlab.fullpath']).to eq "#{group.full_path}/#{project.path}"
    end
  end

  context 'when transfer fails' do
    let!(:original_path) { project_path(project) }

    def attempt_project_transfer(&block)
      expect do
        transfer_project(project, user, group, &block)
      end.to raise_error(ActiveRecord::ActiveRecordError)
    end

    before do
      group.add_owner(user)

      expect_any_instance_of(Labels::TransferService).to receive(:execute).and_raise(ActiveRecord::StatementInvalid, "PG ERROR")
    end

    def project_path(project)
      File.join(project.repository_storage_path, "#{project.disk_path}.git")
    end

    def current_path
      project_path(project)
    end

    it 'rolls back repo location' do
      attempt_project_transfer

      expect(Dir.exist?(original_path)).to be_truthy
      expect(original_path).to eq current_path
    end

    it 'rolls back project full path in .git/config' do
      attempt_project_transfer

      expect(project.repository.rugged.config['gitlab.fullpath']).to eq project.full_path
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
  end

  context 'namespace -> no namespace' do
    before do
      @result = transfer_project(project, user, nil)
    end

    it { expect(@result).to eq false }
    it { expect(project.namespace).to eq(user.namespace) }
    it { expect(project.errors.messages[:new_namespace].first).to eq 'Please select a new namespace for your project.' }
  end

  context 'disallow transfering of project with tags' do
    let(:container_repository) { create(:container_repository) }

    before do
      stub_container_registry_config(enabled: true)
      stub_container_registry_tags(repository: :any, tags: ['tag'])
      project.container_repositories << container_repository
    end

    subject { transfer_project(project, user, group) }

    it { is_expected.to be_falsey }
  end

  context 'namespace -> not allowed namespace' do
    before do
      @result = transfer_project(project, user, group)
    end

    it { expect(@result).to eq false }
    it { expect(project.namespace).to eq(user.namespace) }
  end

  context 'namespace which contains orphan repository with same projects path name' do
    let(:repository_storage) { 'default' }
    let(:repository_storage_path) { Gitlab.config.repositories.storages[repository_storage].legacy_disk_path }

    before do
      group.add_owner(user)

      unless gitlab_shell.add_repository(repository_storage, "#{group.full_path}/#{project.path}")
        raise 'failed to add repository'
      end

      @result = transfer_project(project, user, group)
    end

    after do
      gitlab_shell.remove_repository(repository_storage_path, "#{group.full_path}/#{project.path}")
    end

    it { expect(@result).to eq false }
    it { expect(project.namespace).to eq(user.namespace) }
    it { expect(project.errors[:new_namespace]).to include('Cannot move project') }
  end

  def transfer_project(project, user, new_namespace)
    service = Projects::TransferService.new(project, user)

    yield(service) if block_given?

    service.execute(new_namespace)
  end

  context 'visibility level' do
    let(:internal_group) { create(:group, :internal) }

    before do
      internal_group.add_owner(user)
    end

    context 'when namespace visibility level < project visibility level' do
      let(:public_project) { create(:project, :public, :repository, namespace: user.namespace) }

      before do
        transfer_project(public_project, user, internal_group)
      end

      it { expect(public_project.visibility_level).to eq(internal_group.visibility_level) }
    end

    context 'when namespace visibility level > project visibility level' do
      let(:private_project) { create(:project, :private, :repository, namespace: user.namespace) }

      before do
        transfer_project(private_project, user, internal_group)
      end

      it { expect(private_project.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE) }
    end
  end

  context 'missing group labels applied to issues or merge requests' do
    it 'delegates tranfer to Labels::TransferService' do
      group.add_owner(user)

      expect_any_instance_of(Labels::TransferService).to receive(:execute).once.and_call_original

      transfer_project(project, user, group)
    end
  end

  context 'when hashed storage in use' do
    let(:hashed_project) { create(:project, :repository, namespace: user.namespace) }

    before do
      group.add_owner(user)
    end

    it 'does not move the directory' do
      old_path = hashed_project.repository.disk_path
      old_full_path = hashed_project.repository.full_path

      transfer_project(hashed_project, user, group)
      project.reload

      expect(hashed_project.repository.disk_path).to eq(old_path)
      expect(hashed_project.repository.full_path).to eq(old_full_path)
      expect(hashed_project.disk_path).to eq(old_path)
    end
  end

  describe 'refreshing project authorizations' do
    let(:group) { create(:group) }
    let(:owner) { project.namespace.owner }
    let(:group_member) { create(:user) }

    before do
      group.add_user(owner, GroupMember::MASTER)
      group.add_user(group_member, GroupMember::DEVELOPER)
    end

    it 'refreshes the permissions of the old and new namespace' do
      transfer_project(project, owner, group)

      expect(group_member.authorized_projects).to include(project)
      expect(owner.authorized_projects).to include(project)
    end

    it 'only schedules a single job for every user' do
      expect(UserProjectAccessChangedService).to receive(:new)
        .with([owner.id, group_member.id])
        .and_call_original

      transfer_project(project, owner, group)
    end
  end
end
