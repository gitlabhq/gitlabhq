# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::GroupSearchResults do
  let(:user) { create(:user) }

  describe 'user search' do
    let(:group) { create(:group) }

    it 'returns the users belonging to the group matching the search query' do
      user1 = create(:user, username: 'gob_bluth')
      create(:group_member, :developer, user: user1, group: group)

      user2 = create(:user, username: 'michael_bluth')
      create(:group_member, :developer, user: user2, group: group)

      create(:user, username: 'gob_2018')

      result = described_class.new(user, anything, group, 'gob').objects('users')

      expect(result).to eq [user1]
    end

    it 'returns the user belonging to the subgroup matching the search query' do
      user1 = create(:user, username: 'gob_bluth')
      subgroup = create(:group, parent: group)
      create(:group_member, :developer, user: user1, group: subgroup)

      create(:user, username: 'gob_2018')

      result = described_class.new(user, anything, group, 'gob').objects('users')

      expect(result).to eq [user1]
    end

    it 'returns the user belonging to the parent group matching the search query' do
      user1 = create(:user, username: 'gob_bluth')
      parent_group = create(:group, children: [group])
      create(:group_member, :developer, user: user1, group: parent_group)

      create(:user, username: 'gob_2018')

      result = described_class.new(user, anything, group, 'gob').objects('users')

      expect(result).to eq [user1]
    end

    it 'does not return the user belonging to the private subgroup' do
      user1 = create(:user, username: 'gob_bluth')
      subgroup = create(:group, :private, parent: group)
      create(:group_member, :developer, user: user1, group: subgroup)

      create(:user, username: 'gob_2018')

      result = described_class.new(user, anything, group, 'gob').objects('users')

      expect(result).to eq []
    end

    it 'does not return the user belonging to an unrelated group' do
      user = create(:user, username: 'gob_bluth')
      unrelated_group = create(:group)
      create(:group_member, :developer, user: user, group: unrelated_group)

      result = described_class.new(user, anything, group, 'gob').objects('users')

      expect(result).to eq []
    end
  end
end
