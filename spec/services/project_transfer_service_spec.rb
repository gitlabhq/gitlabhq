require 'spec_helper'

describe ProjectTransferService do
  before(:each) { enable_observers }
  after(:each) {disable_observers}

  context 'namespace -> namespace' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }
    let(:project) { create(:project, namespace: user.namespace) }

    before do
      @result = service.transfer(project, group)
    end

    it { @result.should be_true }
    it { project.namespace.should == group }
  end

  context 'namespace -> no namespace' do
    let(:user) { create(:user) }
    let(:project) { create(:project, namespace: user.namespace) }

    before do
      @result = service.transfer(project, nil)
    end


    it { @result.should be_true }
    it { project.namespace.should == nil }
  end

  context 'no namespace -> namespace' do
    let(:project) { create(:project) }
    let(:user) { create(:user) }

    before do
      @result = service.transfer(project, user.namespace)
    end

    it { @result.should be_true }
    it { project.namespace.should == user.namespace }
  end

  def service
    service = ProjectTransferService.new
    service.gitlab_shell.stub(mv_repository: true)
    service
  end
end

