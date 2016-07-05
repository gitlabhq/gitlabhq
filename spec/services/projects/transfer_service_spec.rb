require 'spec_helper'

describe Projects::TransferService, services: true do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, namespace: user.namespace) }

  context 'namespace -> namespace' do
    before do
      allow_any_instance_of(Gitlab::UploadsTransfer).
        to receive(:move_project).and_return(true)
      allow_any_instance_of(Gitlab::PagesTransfer).
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
end
