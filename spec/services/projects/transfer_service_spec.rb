require 'spec_helper'

describe Projects::TransferService, services: true do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, namespace: user.namespace) }

  context 'namespace -> namespace' do
    before do
      allow_any_instance_of(Gitlab::UploadsTransfer).
        to receive(:move_project).and_return(true)
      group.add_owner(user)
      @result = transfer_project(project, user, group)
    end

    it { expect(@result).to be_truthy }
    it { expect(project.namespace).to eq(group) }
  end

  context 'namespace -> no namespace' do
    before do
      @result = transfer_project(project, user, nil)
    end

    it { expect(@result).to eq false }
    it { expect(project.namespace).to eq(user.namespace) }
  end

  context 'disallow transfering of project with tags' do
    before do
      stub_container_registry_config(enabled: true)
      stub_container_registry_tags('tag')
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

    before { internal_group.add_owner(user) }

    context 'when namespace visibility level < project visibility level' do
      let(:public_project) { create(:project, :public, namespace: user.namespace) }

      before { transfer_project(public_project, user, internal_group) }

      it { expect(public_project.visibility_level).to eq(internal_group.visibility_level) }
    end

    context 'when namespace visibility level > project visibility level' do
      let(:private_project) { create(:project, :private, namespace: user.namespace) }

      before { transfer_project(private_project, user, internal_group) }

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
      expect(UserProjectAccessChangedService).to receive(:new).
        with([owner.id, group_member.id]).
        and_call_original

      transfer_project(project, owner, group)
    end
  end
end
