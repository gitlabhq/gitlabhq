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
end
