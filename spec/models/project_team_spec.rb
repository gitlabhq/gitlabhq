require "spec_helper"

describe ProjectTeam do
  let(:group) { create(:group) }
  let(:project) { create(:empty_project, group: group) }

  let(:master) { create(:user) }
  let(:reporter) { create(:user) }
  let(:guest) { create(:user) }
  let(:nonmember) { create(:user) }

  before do
    group.add_user(master, Gitlab::Access::MASTER)
    group.add_user(reporter, Gitlab::Access::REPORTER)
    group.add_user(guest, Gitlab::Access::GUEST)

    # Add group guest as master to this project
    # to test project access priority over group members
    project.team << [guest, :master]
  end

  describe 'members collection' do
    it { project.team.masters.should include(master) }
    it { project.team.masters.should include(guest) }
    it { project.team.masters.should_not include(reporter) }
    it { project.team.masters.should_not include(nonmember) }
  end

  describe 'access methods' do
    it { project.team.master?(master).should be_true }
    it { project.team.master?(guest).should be_true }
    it { project.team.master?(reporter).should be_false }
    it { project.team.master?(nonmember).should be_false }
  end
end

