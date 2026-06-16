# frozen_string_literal: true

RSpec.shared_context 'with group members shared context' do
  let_it_be(:group, freeze: false) { create(:group) }
  let_it_be(:sub_group_1, freeze: false)     { create(:group, parent: group) }
  let_it_be(:sub_group_2, freeze: false)     { create(:group, parent: group) }
  let_it_be(:sub_sub_group_1, freeze: false) { create(:group, parent: sub_group_1) }
  let_it_be(:sub_sub_sub_group_1, freeze: false) { create(:group, parent: sub_sub_group_1) }
  let_it_be(:shared_group, freeze: false) { create(:group) }

  let_it_be(:group_project_1, freeze: false) { create(:project, group: group) }
  let_it_be(:group_project_2, freeze: false) { create(:project, group: group) }
  let_it_be(:sub_group_1_project, freeze: false) { create(:project, group: sub_group_1) }

  let_it_be(:member_role, freeze: false) { create(:member_role, name: 'Custom role', namespace: group) }

  let_it_be(:link, freeze: false) do
    create(:group_group_link, shared_group: sub_group_1, shared_with_group: shared_group,
      group_access: Gitlab::Access::REPORTER)
  end

  let_it_be(:users, freeze: false) do
    create_list(:user, 6).tap do |result|
      # setting last_activity_on for some users in the list
      result[0].update!(last_activity_on: 1.day.ago)
      result[2].update!(last_activity_on: 3.days.ago)
      result[5].update!(last_activity_on: 4.days.ago)
    end
  end

  let_it_be(:group_owner_1, freeze: false) { create(:group_member, :owner, group: group, user: users[0]) }
  let_it_be(:group_maintainer_2, freeze: false) { create(:group_member, :maintainer, group: group, user: users[1]) }
  let_it_be(:sub_group_1_owner_2, freeze: false) { create(:group_member, :owner, group: sub_group_1, user: users[1]) }
  let_it_be(:group_developer_3, freeze: false) { create(:group_member, :developer, group: group, user: users[2]) }
  let_it_be(:sub_sub_group_owner_4, freeze: false) do
    create(:group_member, :owner, group: sub_sub_group_1, user: users[3])
  end

  let_it_be(:sub_sub_group_owner_5, freeze: false) do
    create(:group_member, :owner, group: sub_sub_group_1, user: users[4])
  end

  let_it_be(:shared_maintainer_5, freeze: false) do
    create(:group_member, :maintainer, group: shared_group, user: users[4])
  end

  let_it_be(:shared_maintainer_6, freeze: false) do
    create(:group_member, :maintainer, group: shared_group, user: users[5])
  end

  let_it_be(:sub_sub_group_invited_developer, freeze: false) do
    create(:group_member, :invited, :developer, group: sub_sub_group_1)
  end

  let_it_be(:group_project_1_owner_5, freeze: false) do
    create(:project_member, :owner, project: group_project_1, user: users[4])
  end

  let_it_be(:group_project_2_owner_6, freeze: false) do
    create(:project_member, :owner, project: group_project_2, user: users[5])
  end

  let_it_be(:sub_group_1_project_maintainer_4, freeze: false) do
    create(:project_member, :maintainer, project: sub_group_1_project, user: users[3], member_role: member_role)
  end
end
