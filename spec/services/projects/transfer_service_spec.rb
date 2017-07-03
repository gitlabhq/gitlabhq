require 'spec_helper'

describe Projects::TransferService, services: true do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, :repository, namespace: user.namespace) }

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
      expect_any_instance_of(SystemHooksService).to receive(:execute_hooks_for).with(project, :transfer)

      transfer_project(project, user, group)
    end
  end

  context 'when transfer fails' do
    let!(:original_path) { project_path(project) }

    def attempt_project_transfer
      expect do
        transfer_project(project, user, group)
      end.to raise_error(ActiveRecord::ActiveRecordError)
    end

    before do
      group.add_owner(user)

      expect_any_instance_of(Labels::TransferService).to receive(:execute).and_raise(ActiveRecord::StatementInvalid, "PG ERROR")
    end

    def project_path(project)
      File.join(project.repository_storage_path, "#{project.path_with_namespace}.git")
    end

    def current_path
      project_path(project)
    end

    it 'rolls back repo location' do
      attempt_project_transfer

      expect(Dir.exist?(original_path)).to be_truthy
      expect(original_path).to eq current_path
    end

    it "doesn't send move notifications" do
      expect_any_instance_of(NotificationService).not_to receive(:project_was_moved)

      attempt_project_transfer
    end

    it "doesn't run system hooks" do
      expect_any_instance_of(SystemHooksService).not_to receive(:execute_hooks_for).with(project, :transfer)

      attempt_project_transfer
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

  def transfer_project(project, user, new_namespace)
    Projects::TransferService.new(project, user).execute(new_namespace)
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
