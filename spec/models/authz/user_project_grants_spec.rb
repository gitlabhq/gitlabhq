# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::UserProjectGrants, feature_category: :permissions do
  let_it_be(:user) { create(:user, :with_namespace) }
  let_it_be(:root) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: root) }
  let_it_be(:project) { create(:project, group: subgroup) }

  subject(:grants) { described_class.new(user.id) }

  def levels(projects)
    grants.max_access_levels(Array(projects).map(&:id))
  end

  def sources(target)
    grants.for_projects([target.id]).fetch(target.id, []).map { |grant| [grant.source, grant.access_level] }
  end

  describe '#for_projects' do
    it 'returns no grants for a user without access' do
      expect(grants.for_projects([project.id])).to eq(project.id => [])
    end

    it 'returns nothing for a user that is not persisted' do
      expect(described_class.new(nil).for_projects([project.id])).to eq({})
    end

    it 'reads the namespace already loaded on a project record without querying it' do
      root.add_developer(user)
      loaded_project = Project.preload(:namespace).find(project.id)

      queries = ActiveRecord::QueryRecorder.new { described_class.new(user.id).for_projects([loaded_project]) }

      expect(queries.log_message).not_to match(/FROM "projects"/)
      expect(sources(project)).to contain_exactly([:group, Gitlab::Access::DEVELOPER])
    end

    it 'accepts a relation' do
      root.add_developer(user)

      expect(grants.for_projects(Project.id_in(project.id)).keys).to contain_exactly(project.id)
    end

    it 'includes a direct project membership' do
      project.add_reporter(user)

      expect(sources(project)).to contain_exactly([:project, Gitlab::Access::REPORTER])
    end

    it 'includes a membership inherited from an ancestor group' do
      root.add_developer(user)

      expect(sources(project)).to contain_exactly([:group, Gitlab::Access::DEVELOPER])
    end

    it 'keeps every role instead of only the highest' do
      root.add_member(user, Gitlab::Access::PLANNER)
      project.add_developer(user)

      expect(sources(project)).to contain_exactly(
        [:group, Gitlab::Access::PLANNER],
        [:project, Gitlab::Access::DEVELOPER]
      )
    end

    it 'ignores access requests and inactive memberships' do
      create(:project_member, :developer, project: project, user: user, requested_at: Time.current)
      create(:group_member, :developer, group: subgroup, user: user, state: Member::STATE_AWAITING)

      expect(sources(project)).to be_empty
    end

    it 'counts expired memberships until they are removed, like project_authorizations' do
      project.add_developer(user).update_column(:expires_at, 1.day.ago)

      expect(sources(project)).to contain_exactly([:project, Gitlab::Access::DEVELOPER])
    end

    it 'keeps minimal access memberships for their custom roles without granting access' do
      create(:group_member, :minimal_access, group: root, user: user)

      expect(sources(project)).to contain_exactly([:group, Gitlab::Access::MINIMAL_ACCESS])
      expect(levels(project)).to eq(project.id => Gitlab::Access::NO_ACCESS)
    end

    it 'gives owners access to projects in their personal namespace' do
      personal_project = create(:project, namespace: user.namespace)

      expect(sources(personal_project)).to include([:personal, Gitlab::Access::OWNER])
    end

    context 'with a group share' do
      let_it_be(:invited_group) { create(:group) }

      before_all do
        create(:group_group_link, :reporter, shared_group: root, shared_with_group: invited_group)
      end

      it 'caps the invited member at the share access level' do
        invited_group.add_maintainer(user)

        expect(sources(project)).to contain_exactly([:group_share, Gitlab::Access::REPORTER])
      end

      it 'does not include members inherited from the invited group parent' do
        parent = create(:group)
        invited_child = create(:group, parent: parent)
        create(:group_group_link, :reporter, shared_group: root, shared_with_group: invited_child)
        parent.add_maintainer(user)

        expect(sources(project)).to be_empty
      end
    end

    context 'with a project share' do
      let_it_be(:invited_parent) { create(:group) }
      let_it_be(:invited_group) { create(:group, parent: invited_parent) }

      before_all do
        create(:project_group_link, project: project, group: invited_group, group_access: Gitlab::Access::REPORTER)
      end

      it 'ignores project shares with groups the user is not a member of' do
        root.add_developer(user)

        expect(sources(project)).to contain_exactly([:group, Gitlab::Access::DEVELOPER])
      end

      it 'includes members inherited from the invited group parent, capped at the share access level' do
        invited_parent.add_maintainer(user)

        expect(sources(project)).to contain_exactly([:project_share, Gitlab::Access::REPORTER])
      end

      it 'applies both caps when the invited group is reached through a group share' do
        other_group = create(:group)
        create(:group_group_link, :guest, shared_group: invited_group, shared_with_group: other_group)
        other_group.add_owner(user)

        expect(sources(project)).to contain_exactly([:project_share, Gitlab::Access::GUEST])
      end

      it 'includes members of groups shared into the invited group or its ancestors, as project_authorizations does' do
        # The project is shared with C in A -> B -> C. C is shared with D, and B is shared with F.
        # F's members reach C through B, so they count as members of the invited group.
        group_a = create(:group)
        group_b = create(:group, parent: group_a)
        group_c = create(:group, parent: group_b)
        group_d = create(:group)
        group_f = create(:group)
        shared_project = create(:project)
        create(:project_group_link, project: shared_project, group: group_c, group_access: Gitlab::Access::DEVELOPER)
        create(:group_group_link, :developer, shared_group: group_c, shared_with_group: group_d)
        create(:group_group_link, :developer, shared_group: group_b, shared_with_group: group_f)

        { a: group_a, b: group_b, c: group_c, d: group_d, f: group_f }.each do |name, group|
          member = create(:user)
          group.add_developer(member)
          authorized = Gitlab::ProjectAuthorizations.new(member).calculate.any? { |row| row.project_id == shared_project.id }

          expect(authorized).to be(true), "project_authorizations, member of #{name}"
          expect(described_class.new(member.id).max_access_levels([shared_project.id]))
            .to eq(shared_project.id => Gitlab::Access::DEVELOPER), "member of #{name}"
        end
      end

      it 'ignores project shares when the project group locks sharing' do
        locked_project = create(:project, group: create(:group, share_with_group_lock: true))
        create(:project_group_link, project: locked_project, group: invited_group)
        invited_parent.add_maintainer(user)

        expect(sources(locked_project)).to be_empty
      end

      it 'treats a share lock that is not set as locked, like project_authorizations' do
        unset_project = create(:project, group: create(:group))
        unset_project.namespace.update_column(:share_with_group_lock, nil)
        create(:project_group_link, project: unset_project, group: invited_group)
        invited_parent.add_maintainer(user)

        expect(sources(unset_project)).to be_empty
        expect(Gitlab::ProjectAuthorizations.new(user).calculate.map(&:project_id)).not_to include(unset_project.id)
      end
    end
  end

  describe '#max_access_levels' do
    it 'matches the access levels calculated for project_authorizations' do
      other_root = create(:group)
      invited = create(:group)
      locked_group = create(:group, parent: other_root, share_with_group_lock: true)

      projects = [
        project,
        create(:project, group: root),
        create(:project, group: other_root),
        create(:project, group: locked_group),
        create(:project, group: invited),
        create(:project, namespace: user.namespace)
      ]

      root.add_member(user, Gitlab::Access::PLANNER)
      subgroup.add_developer(user)
      invited.add_maintainer(user)
      create(:group_group_link, :reporter, shared_group: other_root, shared_with_group: invited)
      create(:project_group_link, project: projects[2], group: subgroup, group_access: Gitlab::Access::MAINTAINER)
      create(:project_group_link, project: projects[3], group: invited, group_access: Gitlab::Access::GUEST)

      authorized = Gitlab::ProjectAuthorizations.new(user).calculate.to_a
        .group_by(&:project_id).transform_values { |rows| rows.map(&:access_level).max }
      expected = projects.to_h { |project| [project.id, authorized.fetch(project.id, Gitlab::Access::NO_ACCESS)] }

      expect(levels(projects)).to eq(expected)
    end
  end

  describe '.enabled_for?', :request_store do
    it 'records the source used for the request' do
      expect(described_class.enabled_for?(user.id)).to be(true)
      expect(Gitlab::SafeRequestStore[:authz_project_access_source]).to eq('memberships')
    end

    it 'is false for a user that is not persisted' do
      expect(described_class.enabled_for?(nil)).to be(false)
    end

    it 'checks the flag once per user for the request' do
      allow(Feature).to receive(:enabled?).and_call_original
      expect(Feature).to receive(:enabled?).with(:resolve_project_access_from_memberships, anything).once
        .and_call_original

      2.times { described_class.enabled_for?(user.id) }
    end

    context 'when resolve_project_access_from_memberships is disabled' do
      before do
        stub_feature_flags(resolve_project_access_from_memberships: false)
      end

      it 'records project_authorizations as the source' do
        expect(described_class.enabled_for?(user.id)).to be(false)
        expect(Gitlab::SafeRequestStore[:authz_project_access_source]).to eq('project_authorizations')
      end

      it 'is enabled for a user the flag is enabled for' do
        stub_feature_flags(resolve_project_access_from_memberships: user)

        expect(described_class.enabled_for?(user.id)).to be(true)
        expect(described_class.enabled_for?(create(:user).id)).to be(false)
      end
    end
  end

  describe '.forget_memberships', :request_store do
    it 'loads the memberships again after they change in the same request' do
      expect(levels(project)).to eq(project.id => Gitlab::Access::NO_ACCESS)

      root.add_developer(user)
      described_class.forget_memberships(user.id)

      expect(described_class.new(user.id).max_access_levels([project.id]))
        .to eq(project.id => Gitlab::Access::DEVELOPER)
    end
  end

  describe 'query count' do
    it 'does not grow with the number of projects' do
      root.add_developer(user)
      more_projects = create_list(:project, 3, group: subgroup)

      control = ActiveRecord::QueryRecorder.new { described_class.new(user.id).max_access_levels([project.id]) }
      Gitlab::SafeRequestStore.clear!

      expect { described_class.new(user.id).max_access_levels([project.id, *more_projects.map(&:id)]) }
        .not_to exceed_query_limit(control)
    end

    context 'with a request store', :request_store do
      it 'reuses project rows and shares across users in the same request' do
        other_user = create(:user)
        root.add_developer(user)
        root.add_reporter(other_user)
        described_class.new(user.id).for_projects([project.id])

        queries = ActiveRecord::QueryRecorder.new { described_class.new(other_user.id).for_projects([project.id]) }

        expect(queries.log_message).not_to match(/FROM "projects"|FROM "project_group_links"|FROM "group_group_links"/)
        expect(described_class.new(other_user.id).max_access_levels([project.id]))
          .to eq(project.id => Gitlab::Access::REPORTER)
      end

      it 'only loads memberships that can grant access to the checked projects' do
        root.add_developer(user)
        unrelated_groups = create_list(:group, 3)
        unrelated_groups.each { |group| group.add_developer(user) }

        queries = ActiveRecord::QueryRecorder.new { described_class.new(user.id).for_projects([project.id]) }
        members_query = queries.log.find { |sql| sql.include?('FROM "members"') }

        unrelated_groups.each { |group| expect(members_query).not_to match(/\b#{group.id}\b/) }
        expect(members_query).to include(root.id.to_s)
        expect(sources(project)).to contain_exactly([:group, Gitlab::Access::DEVELOPER])
      end

      it 'does not query memberships again for sources already looked up in the request' do
        root.add_developer(user)
        grants.for_projects([project.id])

        expect { described_class.new(user.id).for_projects([project.id]) }.not_to exceed_query_limit(0)
      end
    end
  end
end
