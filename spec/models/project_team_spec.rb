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
      it { expect(project.team.member?(reporter, Gitlab::Access::REPORTER)).to be_truthy }
      it { expect(project.team.member?(guest, Gitlab::Access::REPORTER)).to be_falsey }
      it { expect(project.team.member?(nonmember, Gitlab::Access::GUEST)).to be_falsey }
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
      it { expect(project.team.member?(guest, Gitlab::Access::MASTER)).to be_truthy }
      it { expect(project.team.member?(reporter, Gitlab::Access::MASTER)).to be_falsey }
      it { expect(project.team.member?(nonmember, Gitlab::Access::GUEST)).to be_falsey }
    end
  end

  describe '#find_member' do
    context 'personal project' do
      let(:project) { create(:empty_project) }
      let(:requester) { create(:user) }

      before do
        project.team << [master, :master]
        project.team << [reporter, :reporter]
        project.team << [guest, :guest]
        project.request_access(requester)
      end

      it { expect(project.team.find_member(master.id)).to be_a(ProjectMember) }
      it { expect(project.team.find_member(reporter.id)).to be_a(ProjectMember) }
      it { expect(project.team.find_member(guest.id)).to be_a(ProjectMember) }
      it { expect(project.team.find_member(nonmember.id)).to be_nil }
      it { expect(project.team.find_member(requester.id)).to be_nil }
    end

    context 'group project' do
      let(:group) { create(:group) }
      let(:project) { create(:empty_project, group: group) }
      let(:requester) { create(:user) }

      before do
        group.add_master(master)
        group.add_reporter(reporter)
        group.add_guest(guest)
        group.request_access(requester)
      end

      it { expect(project.team.find_member(master.id)).to be_a(GroupMember) }
      it { expect(project.team.find_member(reporter.id)).to be_a(GroupMember) }
      it { expect(project.team.find_member(guest.id)).to be_a(GroupMember) }
      it { expect(project.team.find_member(nonmember.id)).to be_nil }
      it { expect(project.team.find_member(requester.id)).to be_nil }
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

  describe '#max_member_access' do
    let(:requester) { create(:user) }

    context 'personal project' do
      let(:project) { create(:empty_project) }

      context 'when project is not shared with group' do
        before do
          project.team << [master, :master]
          project.team << [reporter, :reporter]
          project.team << [guest, :guest]
          project.request_access(requester)
        end

        it { expect(project.team.max_member_access(master.id)).to eq(Gitlab::Access::MASTER) }
        it { expect(project.team.max_member_access(reporter.id)).to eq(Gitlab::Access::REPORTER) }
        it { expect(project.team.max_member_access(guest.id)).to eq(Gitlab::Access::GUEST) }
        it { expect(project.team.max_member_access(nonmember.id)).to eq(Gitlab::Access::NO_ACCESS) }
        it { expect(project.team.max_member_access(requester.id)).to eq(Gitlab::Access::NO_ACCESS) }
      end

      context 'when project is shared with group' do
        before do
          group = create(:group)
          project.project_group_links.create(
            group: group,
            group_access: Gitlab::Access::DEVELOPER)

          group.add_master(master)
          group.add_reporter(reporter)
        end

        it { expect(project.team.max_member_access(master.id)).to eq(Gitlab::Access::DEVELOPER) }
        it { expect(project.team.max_member_access(reporter.id)).to eq(Gitlab::Access::REPORTER) }
        it { expect(project.team.max_member_access(nonmember.id)).to eq(Gitlab::Access::NO_ACCESS) }
        it { expect(project.team.max_member_access(requester.id)).to eq(Gitlab::Access::NO_ACCESS) }

        context 'but share_with_group_lock is true' do
          before { project.namespace.update(share_with_group_lock: true) }

          it { expect(project.team.max_member_access(master.id)).to eq(Gitlab::Access::NO_ACCESS) }
          it { expect(project.team.max_member_access(reporter.id)).to eq(Gitlab::Access::NO_ACCESS) }
        end
      end
    end

    context 'group project' do
      let(:group) { create(:group) }
      let(:project) { create(:empty_project, group: group) }

      before do
        group.add_master(master)
        group.add_reporter(reporter)
        group.add_guest(guest)
        group.request_access(requester)
      end

      it { expect(project.team.max_member_access(master.id)).to eq(Gitlab::Access::MASTER) }
      it { expect(project.team.max_member_access(reporter.id)).to eq(Gitlab::Access::REPORTER) }
      it { expect(project.team.max_member_access(guest.id)).to eq(Gitlab::Access::GUEST) }
      it { expect(project.team.max_member_access(nonmember.id)).to eq(Gitlab::Access::NO_ACCESS) }
      it { expect(project.team.max_member_access(requester.id)).to eq(Gitlab::Access::NO_ACCESS) }
    end
  end

  describe "#max_member_access_for_users" do
    it 'returns correct roles for different users' do
      master = create(:user)
      reporter = create(:user)
      promoted_guest = create(:user)
      guest = create(:user)
      project = create(:project)

      project.team << [master, :master]
      project.team << [reporter, :reporter]
      project.team << [promoted_guest, :guest]
      project.team << [guest, :guest]

      group = create(:group)
      group_developer = create(:user)
      second_developer = create(:user)
      project.project_group_links.create(
        group: group,
        group_access: Gitlab::Access::DEVELOPER)

      group.add_master(promoted_guest)
      group.add_developer(group_developer)
      group.add_developer(second_developer)

      second_group = create(:group)
      project.project_group_links.create(
          group: second_group,
          group_access: Gitlab::Access::MASTER)
      second_group.add_master(second_developer)

      users = [master, reporter, promoted_guest, guest, group_developer, second_developer].map(&:id)

      expected = {
          master.id => Gitlab::Access::MASTER,
          reporter.id => Gitlab::Access::REPORTER,
          promoted_guest.id => Gitlab::Access::DEVELOPER,
          guest.id => Gitlab::Access::GUEST,
          group_developer.id => Gitlab::Access::DEVELOPER,
          second_developer.id => Gitlab::Access::MASTER
      }

      expect(project.team.max_member_access_for_user_ids(users)).to eq(expected)
    end
  end
end
