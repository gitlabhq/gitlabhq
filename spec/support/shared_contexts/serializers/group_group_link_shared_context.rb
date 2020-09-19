# frozen_string_literal: true

RSpec.shared_context 'group_group_link' do
  let(:shared_with_group) { create(:group) }
  let(:shared_group) { create(:group) }

  let!(:group_group_link) do
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
