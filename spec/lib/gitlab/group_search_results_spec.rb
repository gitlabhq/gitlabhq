# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GroupSearchResults do
  # group creation calls GroupFinder, so need to create the group
  # before so expect(GroupsFinder) check works
  let_it_be(:group) { create(:group) }
  let(:user) { create(:user) }

  subject(:results) { described_class.new(user, 'gob', anything, group: group) }

  describe 'user search' do
    subject(:objects) { results.objects('users') }

    it 'returns the users belonging to the group matching the search query' do
      user1 = create(:user, username: 'gob_bluth')
      create(:group_member, :developer, user: user1, group: group)

      user2 = create(:user, username: 'michael_bluth')
      create(:group_member, :developer, user: user2, group: group)

      create(:user, username: 'gob_2018')

      is_expected.to eq [user1]
    end

    it 'returns the user belonging to the subgroup matching the search query' do
      user1 = create(:user, username: 'gob_bluth')
      subgroup = create(:group, parent: group)
      create(:group_member, :developer, user: user1, group: subgroup)

      create(:user, username: 'gob_2018')

      is_expected.to eq [user1]
    end

    it 'returns the user belonging to the parent group matching the search query' do
      user1 = create(:user, username: 'gob_bluth')
      parent_group = create(:group, children: [group])
      create(:group_member, :developer, user: user1, group: parent_group)

      create(:user, username: 'gob_2018')

      is_expected.to eq [user1]
    end

    it 'does not return the user belonging to the private subgroup' do
      user1 = create(:user, username: 'gob_bluth')
      subgroup = create(:group, :private, parent: group)
      create(:group_member, :developer, user: user1, group: subgroup)

      create(:user, username: 'gob_2018')

      is_expected.to be_empty
    end

    it 'does not return the user belonging to an unrelated group' do
      user = create(:user, username: 'gob_bluth')
      unrelated_group = create(:group)
      create(:group_member, :developer, user: user, group: unrelated_group)

      is_expected.to be_empty
    end

    it 'does not return the user invited to the group' do
      user = create(:user, username: 'gob_bluth')
      create(:group_member, :invited, :developer, user: user, group: group)

      is_expected.to be_empty
    end

    it 'calls GroupFinder during execution' do
      expect(GroupsFinder).to receive(:new).with(user).and_call_original

      subject
    end
  end

  describe "#issuable_params" do
    it 'sets include_subgroups flag by default' do
      expect(results.issuable_params[:include_subgroups]).to eq(true)
    end
  end
end
