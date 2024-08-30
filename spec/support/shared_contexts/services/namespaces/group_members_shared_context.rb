# frozen_string_literal: true

RSpec.shared_context 'with group members shared context' do
  let_it_be(:group) { create(:group) }
  let_it_be(:sub_group_1)     { create(:group, parent: group) }
  let_it_be(:sub_group_2)     { create(:group, parent: group) }
  let_it_be(:sub_sub_group_1) { create(:group, parent: sub_group_1) }
  let_it_be(:sub_sub_sub_group_1) { create(:group, parent: sub_sub_group_1) }
  let_it_be(:shared_group) { create(:group) }

  let_it_be(:link) do
    create(:group_group_link, shared_group: sub_group_1, shared_with_group: shared_group)
  end

  let_it_be(:users) { create_list(:user, 6) }

  let_it_be(:group_owner_1) { create(:group_member, :owner, group: group, user: users[0]) }
  let_it_be(:group_maintainer_2) { create(:group_member, :maintainer, group: group, user: users[1]) }
  let_it_be(:sub_group_1_owner_2) { create(:group_member, :owner, group: sub_group_1, user: users[1]) }
  let_it_be(:group_developer_3) { create(:group_member, :developer, group: group, user: users[2]) }
  let_it_be(:sub_sub_group_owner_4) { create(:group_member, :owner, group: sub_sub_group_1, user: users[3]) }
  let_it_be(:sub_sub_group_owner_5) { create(:group_member, :owner, group: sub_sub_group_1, user: users[4]) }
  let_it_be(:shared_maintainer_5) { create(:group_member, :maintainer, group: shared_group, user: users[4]) }
  let_it_be(:shared_maintainer_6) { create(:group_member, :maintainer, group: shared_group, user: users[5]) }
end
