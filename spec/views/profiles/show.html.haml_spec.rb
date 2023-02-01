# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'profiles/show' do
  let_it_be(:user_status) { create(:user_status, clear_status_at: 8.hours.from_now) }
  let_it_be(:user) { user_status.user }

  before do
    assign(:user, user)
    allow(controller).to receive(:current_user).and_return(user)
    allow(view).to receive(:experiment_enabled?)
  end

  context 'when the profile page is opened' do
    it 'displays the correct elements' do
      render

      expect(rendered).to have_field('user_name', with: user.name)
      expect(rendered).to have_field('user_id', with: user.id)

      expectd_link = help_page_path('user/profile/index', anchor: 'change-the-email-displayed-on-your-commits')
      expected_link_html = "<a href=\"#{expectd_link}\" target=\"_blank\" " \
                           "rel=\"noopener noreferrer\">#{_('Learn more.')}</a>"
      expect(rendered.include?(expected_link_html)).to eq(true)
    end

    it 'renders required hidden inputs for set status form' do
      render

      expect(rendered).to have_field(
        'user[status][emoji]',
        with: user_status.emoji,
        type: :hidden
      )
      expect(rendered).to have_field(
        'user[status][message]',
        with: user_status.message,
        type: :hidden
      )
      expect(rendered).to have_field(
        'user[status][availability]',
        with: user_status.availability,
        type: :hidden
      )
      expect(rendered).to have_field(
        'user[status][clear_status_after]',
        with: user_status.clear_status_at.to_s(:iso8601),
        type: :hidden
      )
    end
  end
end
