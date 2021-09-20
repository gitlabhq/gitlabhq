# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/group_members/index', :aggregate_failures do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before do
    allow(view).to receive(:group_members_app_data).and_return({})
    allow(view).to receive(:current_user).and_return(user)
    assign(:group, group)
    assign(:group_member, build(:group_member, group: group))
  end

  context 'when user can invite members for the group' do
    before do
      group.add_owner(user)
    end

    context 'when modal is enabled' do
      it 'renders as expected' do
        render

        expect(rendered).to have_content('Group members')
        expect(rendered).to have_content('You can invite a new member')

        expect(rendered).to have_selector('.js-invite-group-trigger')
        expect(rendered).to have_selector('.js-invite-members-trigger')
        expect(response).to render_template(partial: 'groups/_invite_members_modal')

        expect(rendered).not_to have_selector('#invite-member-tab')
        expect(rendered).not_to have_selector('#invite-group-tab')
        expect(response).not_to render_template(partial: 'shared/members/_invite_group')
      end
    end

    context 'when modal is not enabled' do
      before do
        stub_feature_flags(invite_members_group_modal: false)
      end

      it 'renders as expected' do
        render

        expect(rendered).to have_content('Group members')
        expect(rendered).to have_content('You can invite a new member')

        expect(rendered).to have_selector('#invite-member-tab')
        expect(rendered).to have_selector('#invite-group-tab')
        expect(response).to render_template(partial: 'shared/members/_invite_group')

        expect(rendered).not_to have_selector('.js-invite-group-trigger')
        expect(rendered).not_to have_selector('.js-invite-members-trigger')
        expect(response).not_to render_template(partial: 'groups/_invite_members_modal')
      end
    end
  end

  context 'when user can not invite members for the group' do
    it 'renders as expected', :aggregate_failures do
      render

      expect(rendered).not_to have_content('Group members')
      expect(rendered).not_to have_content('You can invite a new member')
    end
  end
end
