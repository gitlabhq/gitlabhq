# frozen_string_literal: true

RSpec.shared_context 'with group members shared context' do
  let_it_be(:group) { create(:group) }
  let_it_be(:sub_group_1)     { create(:group, parent: group) }
  let_it_be(:sub_group_2)     { create(:group, parent: group) }
  let_it_be(:sub_sub_group_1) { create(:group, parent: sub_group_1) }
  let_it_be(:sub_sub_sub_group_1) { create(:group, parent: sub_sub_group_1) }
  let_it_be(:shared_group) { create(:group) }

  let_it_be(:group_project_1) { create(:project, group: group) }
  let_it_be(:group_project_2) { create(:project, group: group) }
  let_it_be(:sub_group_1_project) { create(:project, group: sub_group_1) }

  let_it_be(:member_role) { create(:member_role, name: 'Custom role', namespace: group) }

  let_it_be(:link) do
    create(:group_group_link, shared_group: sub_group_1, shared_with_group: shared_group,
      group_access: Gitlab::Access::REPORTER)
  end

  let_it_be(:users) do
    create_list(:user, 6).tap do |result|
      # setting last_activity_on for some users in the list
      result[0].update!(last_activity_on: 1.day.ago)
      result[2].update!(last_activity_on: 3.days.ago)
      result[5].update!(last_activity_on: 4.days.ago)
    end
  end

  let_it_be(:group_owner_1) { create(:group_member, :owner, group: group, user: users[0]) }
  let_it_be(:group_maintainer_2) { create(:group_member, :maintainer, group: group, user: users[1]) }
  let_it_be(:sub_group_1_owner_2) { create(:group_member, :owner, group: sub_group_1, user: users[1]) }
  let_it_be(:group_developer_3) { create(:group_member, :developer, group: group, user: users[2]) }
  let_it_be(:sub_sub_group_owner_4) { create(:group_member, :owner, group: sub_sub_group_1, user: users[3]) }
  let_it_be(:sub_sub_group_owner_5) { create(:group_member, :owner, group: sub_sub_group_1, user: users[4]) }
  let_it_be(:shared_maintainer_5) { create(:group_member, :maintainer, group: shared_group, user: users[4]) }
  let_it_be(:shared_maintainer_6) { create(:group_member, :maintainer, group: shared_group, user: users[5]) }
  let_it_be(:sub_sub_group_invited_developer) { create(:group_member, :invited, :developer, group: sub_sub_group_1) }

  let_it_be(:group_project_1_owner_5) { create(:project_member, :owner, project: group_project_1, user: users[4]) }
  let_it_be(:group_project_2_owner_6) { create(:project_member, :owner, project: group_project_2, user: users[5]) }
  let_it_be(:sub_group_1_project_maintainer_4) do
    create(:project_member, :maintainer, project: sub_group_1_project, user: users[3], member_role: member_role)
  end
end
