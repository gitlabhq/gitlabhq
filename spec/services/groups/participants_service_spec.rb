# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::ParticipantsService do
  describe '#group_members' do
    let(:user) { create(:user) }
    let(:parent_group) { create(:group) }
    let(:group) { create(:group, parent: parent_group) }
    let(:subgroup) { create(:group, parent: group) }
    let(:subproject) { create(:project, group: subgroup) }

    it 'returns all members in parent groups, sub-groups, and sub-projects' do
      parent_group.add_developer(create(:user))
      subgroup.add_developer(create(:user))
      subproject.add_developer(create(:user))

      result = described_class.new(group, user).execute(nil)

      expected_users = (group.self_and_hierarchy.flat_map(&:users) + subproject.users)
        .map { |user| user_to_autocompletable(user) }

      expect(expected_users.count).to eq(3)
      expect(result).to include(*expected_users)
    end
  end

  def user_to_autocompletable(user)
    {
      type: user.class.name,
      username: user.username,
      name: user.name,
      avatar_url: user.avatar_url,
      availability: user&.status&.availability
    }
  end
end
