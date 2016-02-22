require "spec_helper"

describe ProjectTeam, models: true do
  let(:master) { create(:user) }
  let(:reporter) { create(:user) }
  let(:guest) { create(:user) }
  let(:nonmember) { create(:user) }

  context 'personal project' do
    let(:project) { create(:empty_project) }

    before do
      project.team << [master, :master]
      project.team << [reporter, :reporter]
      project.team << [guest, :guest]
    end

    describe 'members collection' do
      it { expect(project.team.masters).to include(master) }
      it { expect(project.team.masters).not_to include(guest) }
      it { expect(project.team.masters).not_to include(reporter) }
      it { expect(project.team.masters).not_to include(nonmember) }
    end

    describe 'access methods' do
      it { expect(project.team.master?(master)).to be_truthy }
      it { expect(project.team.master?(guest)).to be_falsey }
      it { expect(project.team.master?(reporter)).to be_falsey }
      it { expect(project.team.master?(nonmember)).to be_falsey }
      it { expect(project.team.member?(nonmember)).to be_falsey }
      it { expect(project.team.member?(guest)).to be_truthy }
    end
  end

  context 'group project' do
    let(:group) { create(:group) }
    let(:project) { create(:empty_project, group: group) }

    before do
      group.add_master(master)
      group.add_reporter(reporter)
      group.add_guest(guest)

      # If user is a group and a project member - GitLab uses highest permission
      # So we add group guest as master and add group master as guest
      # to this project to test highest access
      project.team << [guest, :master]
      project.team << [master, :guest]
    end

    describe 'members collection' do
      it { expect(project.team.reporters).to include(reporter) }
      it { expect(project.team.masters).to include(master) }
      it { expect(project.team.masters).to include(guest) }
      it { expect(project.team.masters).not_to include(reporter) }
      it { expect(project.team.masters).not_to include(nonmember) }
    end

    describe 'access methods' do
      it { expect(project.team.reporter?(reporter)).to be_truthy }
      it { expect(project.team.master?(master)).to be_truthy }
      it { expect(project.team.master?(guest)).to be_truthy }
      it { expect(project.team.master?(reporter)).to be_falsey }
      it { expect(project.team.master?(nonmember)).to be_falsey }
      it { expect(project.team.member?(nonmember)).to be_falsey }
      it { expect(project.team.member?(guest)).to be_truthy }
    end
  end

  describe "#human_max_access" do
    it 'returns Master role' do
      user = create(:user)
      group = create(:group)
      group.add_master(user)

      project = build_stubbed(:empty_project, namespace: group)

      expect(project.team.human_max_access(user.id)).to eq 'Master'
    end

    it 'returns Owner role' do
      user = create(:user)
      group = create(:group)
      group.add_owner(user)

      project = build_stubbed(:empty_project, namespace: group)

      expect(project.team.human_max_access(user.id)).to eq 'Owner'
    end
  end
end
