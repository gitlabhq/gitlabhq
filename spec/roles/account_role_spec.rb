require 'spec_helper'

describe User, "Account" do
  describe 'normal user' do
    let(:user) { create(:user, name: 'John Smith') }

    it { user.is_admin?.should be_false }
    it { user.require_ssh_key?.should be_true }
    it { user.can_create_group?.should be_false }
    it { user.can_create_project?.should be_true }
    it { user.first_name.should == 'John' }
  end

  describe 'blocking user' do
    let(:user) { create(:user, name: 'John Smith') }

    it "should block user" do
      user.block
      user.blocked.should be_true
    end
  end

  describe 'projects' do
    before do
      ActiveRecord::Base.observers.enable(:user_observer)
      @user = create :user
      @project = create :project, namespace: @user.namespace
    end

    it { @user.authorized_projects.should include(@project) }
    it { @user.my_own_projects.should include(@project) }
  end

  describe 'namespaced' do
    before do
      ActiveRecord::Base.observers.enable(:user_observer)
      @user = create :user
      @project = create :project, namespace: @user.namespace
    end

    it { @user.several_namespaces?.should be_false }
    it { @user.namespaces.should == [@user.namespace] }
  end
end
