# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/group_members/index', :aggregate_failures, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) } # rubocop:todo RSpec/FactoryBot/AvoidCreate
  let_it_be(:group) { create(:group) } # rubocop:todo RSpec/FactoryBot/AvoidCreate

  before do
    allow(view).to receive(:group_members_app_data).and_return({})
    allow(view).to receive(:current_user).and_return(user)
    assign(:group, group)
  end

  context 'when user can invite members for the group' do
    before do
      group.add_owner(user)
    end

    it 'renders as expected' do
      render

      expect(rendered).to have_content('Group members')
      expect(rendered).to have_content("You're viewing members")

      expect(rendered).to have_selector('.js-invite-group-trigger')
      expect(rendered).to have_selector('.js-invite-members-trigger')
    end
  end

  context 'when user can not invite members for the group' do
    it 'renders as expected', :aggregate_failures do
      render

      expect(rendered).not_to have_content('Group members')
      expect(rendered).not_to have_content('You can invite a new member')
    end
  end

  context 'when @banned is nil' do
    before do
      assign(:banned, nil)
    end

    it 'calls group_members_app_data with { banned: [] }' do
      expect(view).to receive(:group_members_app_data).with(group, a_hash_including(banned: []))

      render
    end
  end
end
