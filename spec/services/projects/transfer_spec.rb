require 'spec_helper'

describe Projects::Transfer do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:group2) { create(:group) }
  let(:project) { create(:project, namespace: user.namespace) }

  before do
    Projects::TransferProject.any_instance.gitlab_shell.stub(mv_repository: true)
    Projects::TransferWiki.any_instance.gitlab_shell.stub(mv_repository: true)
  end

  after do
    Projects::TransferProject.any_instance.gitlab_shell.unstub(:mv_repository)
    Projects::TransferWiki.any_instance.gitlab_shell.unstub(:mv_repository)
  end

  context 'namespace -> namespace' do
    before do
      group.add_owner(user)
      @result = Projects::Transfer.perform(project: project,
                                           user: user,
                                           params: { namespace_id: group.id })
    end

    it { @result.should be_success }
    it { project.namespace.should == group }
  end

  context 'namespace -> no namespace' do
    before do
      group.add_owner(user)

      @result = Projects::Transfer.perform(project: project,
                                           user: user,
                                           params: { namespace_id: nil })
    end

    it { @result.should_not be_success }
    it { project.namespace.should == user.namespace }
  end

  context 'namespace -> not allowed namespace' do
    before do
      @result = Projects::Transfer.perform(project: project,
                                           user: user,
                                           params: { namespace_id: group2.id })
    end

    it { @result.should_not be_success }
    it { project.namespace.should == user.namespace }
  end
end
