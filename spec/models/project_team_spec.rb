# frozen_string_literal: true

require "spec_helper"

RSpec.describe ProjectTeam do
  include ProjectForksHelper

  let(:maintainer) { create(:user) }
  let(:reporter) { create(:user) }
  let(:guest) { create(:user) }
  let(:nonmember) { create(:user) }

  context 'personal project' do
    let(:project) { create(:project) }

    before do
      project.add_maintainer(maintainer)
      project.add_reporter(reporter)
      project.add_guest(guest)
    end

    describe 'members collection' do
      it { expect(project.team.maintainers).to include(maintainer) }
      it { expect(project.team.maintainers).not_to include(guest) }
      it { expect(project.team.maintainers).not_to include(reporter) }
      it { expect(project.team.maintainers).not_to include(nonmember) }
    end

    describe 'access methods' do
      it { expect(project.team.maintainer?(maintainer)).to be_truthy }
      it { expect(project.team.maintainer?(guest)).to be_falsey }
      it { expect(project.team.maintainer?(reporter)).to be_falsey }
      it { expect(project.team.maintainer?(nonmember)).to be_falsey }
      it { expect(project.team.member?(nonmember)).to be_falsey }
      it { expect(project.team.member?(guest)).to be_truthy }
      it { expect(project.team.member?(reporter, Gitlab::Access::REPORTER)).to be_truthy }
      it { expect(project.team.member?(guest, Gitlab::Access::REPORTER)).to be_falsey }
      it { expect(project.team.member?(nonmember, Gitlab::Access::GUEST)).to be_falsey }
    end
  end

  context 'group project' do
    let(:group) { create(:group) }
    let!(:project) { create(:project, group: group) }

    before do
      group.add_maintainer(maintainer)
      group.add_reporter(reporter)
      group.add_guest(guest)

      # If user is a group and a project member - GitLab uses highest permission
      # So we add group guest as maintainer and add group maintainer as guest
      # to this project to test highest access
      project.add_maintainer(guest)
      project.add_guest(maintainer)
    end

    describe 'members collection' do
      it { expect(project.team.reporters).to include(reporter) }
      it { expect(project.team.maintainers).to include(maintainer) }
      it { expect(project.team.maintainers).to include(guest) }
      it { expect(project.team.maintainers).not_to include(reporter) }
      it { expect(project.team.maintainers).not_to include(nonmember) }
    end

    describe 'access methods' do
      it { expect(project.team.reporter?(reporter)).to be_truthy }
      it { expect(project.team.maintainer?(maintainer)).to be_truthy }
      it { expect(project.team.maintainer?(guest)).to be_truthy }
      it { expect(project.team.maintainer?(reporter)).to be_falsey }
      it { expect(project.team.maintainer?(nonmember)).to be_falsey }
      it { expect(project.team.member?(nonmember)).to be_falsey }
      it { expect(project.team.member?(guest)).to be_truthy }
      it { expect(project.team.member?(guest, Gitlab::Access::MAINTAINER)).to be_truthy }
      it { expect(project.team.member?(reporter, Gitlab::Access::MAINTAINER)).to be_falsey }
      it { expect(project.team.member?(nonmember, Gitlab::Access::GUEST)).to be_falsey }
    end
  end

  describe '#fetch_members' do
    context 'personal project' do
      let(:project) { create(:project) }

      it 'returns project members' do
        user = create(:user)
        project.add_guest(user)

        expect(project.team.members).to contain_exactly(user, project.owner)
      end

      it 'returns project members of a specified level' do
        user = create(:user)
        project.add_reporter(user)

        expect(project.team.guests).to be_empty
        expect(project.team.reporters).to contain_exactly(user)
      end

      it 'returns invited members of a group' do
        group_member = create(:group_member)
        create(:project_group_link, group: group_member.group,
                                    project: project,
                                    group_access: Gitlab::Access::GUEST)

        expect(project.team.members)
          .to contain_exactly(group_member.user, project.owner)
      end

      it 'returns invited members of a group of a specified level' do
        group_member = create(:group_member)
        create(:project_group_link, group: group_member.group,
                                    project: project,
                                    group_access: Gitlab::Access::REPORTER)

        expect(project.team.guests).to be_empty
        expect(project.team.reporters).to contain_exactly(group_member.user)
      end
    end

    context 'group project' do
      let(:group) { create(:group) }
      let!(:project) { create(:project, group: group) }

      it 'returns project members' do
        group_member = create(:group_member, group: group)

        expect(project.team.members).to contain_exactly(group_member.user)
      end

      it 'returns project members of a specified level' do
        group_member = create(:group_member, :reporter, group: group)

        expect(project.team.guests).to be_empty
        expect(project.team.reporters).to contain_exactly(group_member.user)
      end
    end
  end

  describe '#find_member' do
    context 'personal project' do
      let(:project) do
        create(:project, :public)
      end

      let(:requester) { create(:user) }

      before do
        project.add_maintainer(maintainer)
        project.add_reporter(reporter)
        project.add_guest(guest)
        project.request_access(requester)
      end

      it { expect(project.team.find_member(maintainer.id)).to be_a(ProjectMember) }
      it { expect(project.team.find_member(reporter.id)).to be_a(ProjectMember) }
      it { expect(project.team.find_member(guest.id)).to be_a(ProjectMember) }
      it { expect(project.team.find_member(nonmember.id)).to be_nil }
      it { expect(project.team.find_member(requester.id)).to be_nil }
    end

    context 'group project' do
      let(:group) { create(:group) }
      let(:project) { create(:project, group: group) }
      let(:requester) { create(:user) }

      before do
        group.add_maintainer(maintainer)
        group.add_reporter(reporter)
        group.add_guest(guest)
        group.request_access(requester)
      end

      it { expect(project.team.find_member(maintainer.id)).to be_a(GroupMember) }
      it { expect(project.team.find_member(reporter.id)).to be_a(GroupMember) }
      it { expect(project.team.find_member(guest.id)).to be_a(GroupMember) }
      it { expect(project.team.find_member(nonmember.id)).to be_nil }
      it { expect(project.team.find_member(requester.id)).to be_nil }
    end
  end

  describe '#members_in_project_and_ancestors' do
    context 'group project' do
      it 'filters out users who are not members of the project' do
        group = create(:group)
        project = create(:project, group: group)
        group_member = create(:group_member, group: group)
        old_user = create(:user)

        ProjectAuthorization.create!(project: project, user: old_user, access_level: Gitlab::Access::GUEST)

        expect(project.team.members_in_project_and_ancestors).to contain_exactly(group_member.user)
      end
    end
  end

  describe '#add_users' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:project) { create(:project) }

    it 'add the given users to the team' do
      project.team.add_users([user1, user2], :reporter)

      expect(project.team.reporter?(user1)).to be(true)
      expect(project.team.reporter?(user2)).to be(true)
    end
  end

  describe '#add_user' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }

    it 'add the given user to the team' do
      project.team.add_user(user, :reporter)

      expect(project.team.reporter?(user)).to be(true)
    end
  end

  describe "#human_max_access" do
    it 'returns Maintainer role' do
      user = create(:user)
      group = create(:group)
      project = create(:project, namespace: group)

      group.add_maintainer(user)

      expect(project.team.human_max_access(user.id)).to eq 'Maintainer'
    end

    it 'returns Owner role' do
      user = create(:user)
      group = create(:group)
      project = create(:project, namespace: group)

      group.add_owner(user)

      expect(project.team.human_max_access(user.id)).to eq 'Owner'
    end
  end

  describe '#contributor?' do
    let(:project) { create(:project, :public, :repository) }

    context 'when user is a member of project' do
      before do
        project.add_maintainer(maintainer)
        project.add_reporter(reporter)
        project.add_guest(guest)
      end

      it { expect(project.team.contributor?(maintainer.id)).to be false }
      it { expect(project.team.contributor?(reporter.id)).to be false }
      it { expect(project.team.contributor?(guest.id)).to be false }
    end

    context 'when user has at least one merge request merged into default_branch' do
      let(:contributor) { create(:user) }
      let(:user_without_access) { create(:user) }
      let(:first_fork_project) { fork_project(project, contributor, repository: true) }

      before do
        create(:merge_request, :merged, author: contributor, target_project: project, source_project: first_fork_project, target_branch: project.default_branch.to_s)
      end

      it { expect(project.team.contributor?(contributor.id)).to be true }
      it { expect(project.team.contributor?(user_without_access.id)).to be false }
    end
  end

  describe '#max_member_access' do
    let(:requester) { create(:user) }

    context 'personal project' do
      let(:project) do
        create(:project, :public)
      end

      context 'when project is not shared with group' do
        before do
          project.add_maintainer(maintainer)
          project.add_reporter(reporter)
          project.add_guest(guest)
          project.request_access(requester)
        end

        it { expect(project.team.max_member_access(maintainer.id)).to eq(Gitlab::Access::MAINTAINER) }
        it { expect(project.team.max_member_access(reporter.id)).to eq(Gitlab::Access::REPORTER) }
        it { expect(project.team.max_member_access(guest.id)).to eq(Gitlab::Access::GUEST) }
        it { expect(project.team.max_member_access(nonmember.id)).to eq(Gitlab::Access::NO_ACCESS) }
        it { expect(project.team.max_member_access(requester.id)).to eq(Gitlab::Access::NO_ACCESS) }
      end

      context 'when project is shared with group' do
        before do
          group = create(:group)
          project.project_group_links.create!(
            group: group,
            group_access: Gitlab::Access::DEVELOPER)

          group.add_maintainer(maintainer)
          group.add_reporter(reporter)
        end

        it { expect(project.team.max_member_access(maintainer.id)).to eq(Gitlab::Access::DEVELOPER) }
        it { expect(project.team.max_member_access(reporter.id)).to eq(Gitlab::Access::REPORTER) }
        it { expect(project.team.max_member_access(nonmember.id)).to eq(Gitlab::Access::NO_ACCESS) }
        it { expect(project.team.max_member_access(requester.id)).to eq(Gitlab::Access::NO_ACCESS) }

        context 'but share_with_group_lock is true' do
          before do
            project.namespace.update!(share_with_group_lock: true)
          end

          it { expect(project.team.max_member_access(maintainer.id)).to eq(Gitlab::Access::NO_ACCESS) }
          it { expect(project.team.max_member_access(reporter.id)).to eq(Gitlab::Access::NO_ACCESS) }
        end
      end
    end

    context 'group project' do
      let(:group) { create(:group) }
      let!(:project) do
        create(:project, group: group)
      end

      before do
        group.add_maintainer(maintainer)
        group.add_reporter(reporter)
        group.add_guest(guest)
        group.request_access(requester)
      end

      it { expect(project.team.max_member_access(maintainer.id)).to eq(Gitlab::Access::MAINTAINER) }
      it { expect(project.team.max_member_access(reporter.id)).to eq(Gitlab::Access::REPORTER) }
      it { expect(project.team.max_member_access(guest.id)).to eq(Gitlab::Access::GUEST) }
      it { expect(project.team.max_member_access(nonmember.id)).to eq(Gitlab::Access::NO_ACCESS) }
      it { expect(project.team.max_member_access(requester.id)).to eq(Gitlab::Access::NO_ACCESS) }
    end
  end

  describe '#member?' do
    let(:group) { create(:group) }
    let(:developer) { create(:user) }
    let(:maintainer) { create(:user) }

    let(:personal_project) do
      create(:project, namespace: developer.namespace)
    end

    let(:group_project) do
      create(:project, namespace: group)
    end

    let(:members_project) { create(:project) }
    let(:shared_project) { create(:project) }

    before do
      group.add_maintainer(maintainer)
      group.add_developer(developer)

      members_project.add_developer(developer)
      members_project.add_maintainer(maintainer)

      create(:project_group_link, project: shared_project, group: group)
    end

    it 'returns false for no user' do
      expect(personal_project.team.member?(nil)).to be(false)
    end

    it 'returns true for personal projects of the user' do
      expect(personal_project.team.member?(developer)).to be(true)
    end

    it 'returns true for projects of groups the user is a member of' do
      expect(group_project.team.member?(developer)).to be(true)
    end

    it 'returns true for projects for which the user is a member of' do
      expect(members_project.team.member?(developer)).to be(true)
    end

    it 'returns true for projects shared on a group the user is a member of' do
      expect(shared_project.team.member?(developer)).to be(true)
    end

    it 'checks for the correct minimum level access' do
      expect(group_project.team.member?(developer, Gitlab::Access::MAINTAINER)).to be(false)
      expect(group_project.team.member?(maintainer, Gitlab::Access::MAINTAINER)).to be(true)
      expect(members_project.team.member?(developer, Gitlab::Access::MAINTAINER)).to be(false)
      expect(members_project.team.member?(maintainer, Gitlab::Access::MAINTAINER)).to be(true)
      expect(shared_project.team.member?(developer, Gitlab::Access::MAINTAINER)).to be(false)
      expect(shared_project.team.member?(maintainer, Gitlab::Access::MAINTAINER)).to be(false)
      expect(shared_project.team.member?(developer, Gitlab::Access::DEVELOPER)).to be(true)
      expect(shared_project.team.member?(maintainer, Gitlab::Access::DEVELOPER)).to be(true)
    end
  end

  describe '#contribution_check_for_user_ids', :request_store do
    let(:project) { create(:project, :public, :repository) }
    let(:contributor) { create(:user) }
    let(:second_contributor) { create(:user) }
    let(:user_without_access) { create(:user) }
    let(:first_fork_project) { fork_project(project, contributor, repository: true) }
    let(:second_fork_project) { fork_project(project, second_contributor, repository: true) }

    let(:users) do
      [contributor, second_contributor, user_without_access].map(&:id)
    end

    let(:expected) do
      {
        contributor.id => true,
        second_contributor.id => true,
        user_without_access.id => false
      }
    end

    before do
      create(:merge_request, :merged, author: contributor, target_project: project, source_project: first_fork_project, target_branch: project.default_branch.to_s)
      create(:merge_request, :merged, author: second_contributor, target_project: project, source_project: second_fork_project, target_branch: project.default_branch.to_s)
    end

    def contributors(users)
      project.team.contribution_check_for_user_ids(users)
    end

    it 'does not perform extra queries when asked for users who have already been found' do
      contributors(users)

      expect { contributors([contributor.id]) }.not_to exceed_query_limit(0)

      expect(contributors([contributor.id])).to eq(expected)
    end

    it 'only requests the extra users when uncached users are passed' do
      new_contributor = create(:user)
      new_fork_project = fork_project(project, new_contributor, repository: true)
      second_new_user = create(:user)
      all_users = users + [new_contributor.id, second_new_user.id]
      create(:merge_request, :merged, author: new_contributor, target_project: project, source_project: new_fork_project, target_branch: project.default_branch.to_s)

      expected_all = expected.merge(new_contributor.id => true,
                                    second_new_user.id => false)

      contributors(users)

      queries = ActiveRecord::QueryRecorder.new { contributors(all_users) }

      expect(queries.count).to eq(1)
      expect(contributors([new_contributor.id])).to eq(expected_all)
    end

    it 'returns correct contributors' do
      expect(contributors(users)).to eq(expected)
    end
  end

  shared_examples 'max member access for users' do
    let(:project) { create(:project) }
    let(:group) { create(:group) }
    let(:second_group) { create(:group) }

    let(:maintainer) { create(:user) }
    let(:reporter) { create(:user) }
    let(:guest) { create(:user) }

    let(:promoted_guest) { create(:user) }

    let(:group_developer) { create(:user) }
    let(:second_developer) { create(:user) }

    let(:user_without_access) { create(:user) }
    let(:second_user_without_access) { create(:user) }

    let(:users) do
      [maintainer, reporter, promoted_guest, guest, group_developer, second_developer, user_without_access].map(&:id)
    end

    let(:expected) do
      {
        maintainer.id => Gitlab::Access::MAINTAINER,
        reporter.id => Gitlab::Access::REPORTER,
        promoted_guest.id => Gitlab::Access::DEVELOPER,
        guest.id => Gitlab::Access::GUEST,
        group_developer.id => Gitlab::Access::DEVELOPER,
        second_developer.id => Gitlab::Access::MAINTAINER,
        user_without_access.id => Gitlab::Access::NO_ACCESS
      }
    end

    before do
      project.add_maintainer(maintainer)
      project.add_reporter(reporter)
      project.add_guest(promoted_guest)
      project.add_guest(guest)

      project.project_group_links.create!(
        group: group,
        group_access: Gitlab::Access::DEVELOPER
      )

      group.add_maintainer(promoted_guest)
      group.add_developer(group_developer)
      group.add_developer(second_developer)

      project.project_group_links.create!(
        group: second_group,
        group_access: Gitlab::Access::MAINTAINER
      )

      second_group.add_maintainer(second_developer)
    end

    it 'returns correct roles for different users' do
      expect(project.team.max_member_access_for_user_ids(users)).to eq(expected)
    end
  end

  describe '#max_member_access_for_user_ids' do
    context 'with RequestStore enabled', :request_store do
      include_examples 'max member access for users'

      def access_levels(users)
        project.team.max_member_access_for_user_ids(users)
      end

      it 'does not perform extra queries when asked for users who have already been found' do
        access_levels(users)

        expect { access_levels([maintainer.id]) }.not_to exceed_query_limit(0)

        expect(access_levels([maintainer.id])).to eq(expected)
      end

      it 'only requests the extra users when uncached users are passed' do
        new_user = create(:user)
        second_new_user = create(:user)
        all_users = users + [new_user.id, second_new_user.id]

        expected_all = expected.merge(new_user.id => Gitlab::Access::NO_ACCESS,
                                      second_new_user.id => Gitlab::Access::NO_ACCESS)

        access_levels(users)

        queries = ActiveRecord::QueryRecorder.new { access_levels(all_users) }

        expect(queries.count).to eq(1)
        expect(queries.log_message).to match(/\W#{new_user.id}\W/)
        expect(queries.log_message).to match(/\W#{second_new_user.id}\W/)
        expect(queries.log_message).not_to match(/\W#{promoted_guest.id}\W/)
        expect(access_levels(all_users)).to eq(expected_all)
      end
    end

    context 'with RequestStore disabled' do
      include_examples 'max member access for users'
    end
  end
end
