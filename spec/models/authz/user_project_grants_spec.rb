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
  end

  describe '#max_access_levels' do
    it 'matches the access levels calculated for project_authorizations' do
      other_root = create(:group)

      projects = [
        project,
        create(:project, group: root),
        create(:project, group: other_root),
        create(:project, namespace: user.namespace)
      ]

      root.add_member(user, Gitlab::Access::PLANNER)
      subgroup.add_developer(user)
      projects[2].add_maintainer(user)

      authorized = Gitlab::ProjectAuthorizations.new(user).calculate.to_a
        .group_by(&:project_id).transform_values { |rows| rows.map(&:access_level).max }
      expected = projects.to_h { |project| [project.id, authorized.fetch(project.id, Gitlab::Access::NO_ACCESS)] }

      expect(levels(projects)).to eq(expected)
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
