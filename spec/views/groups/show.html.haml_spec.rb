# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/show.html.haml' do
  let_it_be(:user) { build(:user) }
  let_it_be(:group) { create(:group) }

  before do
    assign(:group, group)
  end

  context 'when rendering with the layout' do
    subject(:render_page) { render template: 'groups/show.html.haml', layout: 'layouts/group' }

    describe 'invite team members' do
      before do
        allow(view).to receive(:session).and_return({})
        allow(view).to receive(:current_user_mode).and_return(Gitlab::Auth::CurrentUserMode.new(user))
        allow(view).to receive(:current_user).and_return(user)
        allow(view).to receive(:experiment_enabled?).and_return(false)
        allow(view).to receive(:group_path).and_return('')
        allow(view).to receive(:group_shared_path).and_return('')
        allow(view).to receive(:group_archived_path).and_return('')
      end

      context 'when invite team members is not available in sidebar' do
        before do
          allow(view).to receive(:can_invite_members_for_group?).and_return(false)
        end

        it 'does not display the js-invite-members-trigger' do
          render_page

          expect(rendered).not_to have_selector('.js-invite-members-trigger')
        end
      end

      context 'when invite team members is available' do
        before do
          allow(view).to receive(:can_invite_members_for_group?).and_return(true)
        end

        it 'includes the div for js-invite-members-trigger' do
          render_page

          expect(rendered).to have_selector('.js-invite-members-trigger')
        end
      end
    end
  end
end
