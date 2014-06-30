require 'spec_helper'

describe Projects::TransferService do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:group2) { create(:group) }
  let(:project) { create(:project, namespace: user.namespace) }

  context 'namespace -> namespace' do
    before do
      group.add_owner(user)
      @service = Projects::TransferService.new(project, user, namespace_id: group.id)
      @service.gitlab_shell.stub(mv_repository: true)
      @result = @service.execute
    end

    it { expect(@result).to be_true }
    it { expect(project.namespace).to eq(group) }
  end

  context 'namespace -> no namespace' do
    before do
      group.add_owner(user)
      @service = Projects::TransferService.new(project, user, namespace_id: nil)
      @service.gitlab_shell.stub(mv_repository: true)
      @result = @service.execute
    end

    it { expect(@result).to be_false }
    it { expect(project.namespace).to eq(user.namespace) }
  end

  context 'namespace -> not allowed namespace' do
    before do
      @service = Projects::TransferService.new(project, user, namespace_id: group2.id)
      @service.gitlab_shell.stub(mv_repository: true)
      @result = @service.execute
    end

    it { expect(@result).to be_false }
    it { expect(project.namespace).to eq(user.namespace) }
  end
end
