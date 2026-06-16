# frozen_string_literal: true

RSpec.shared_context 'group_group_link' do
  let_it_be(:shared_with_group, freeze: false) { create(:group) }
  let_it_be(:shared_group, freeze: false) { create(:group) }

  let_it_be(:group_group_link, freeze: false) do
    create(
      :group_group_link,
      {
        shared_group: shared_group,
        shared_with_group: shared_with_group,
        expires_at: '2020-05-12'
      }
    )
  end
end
