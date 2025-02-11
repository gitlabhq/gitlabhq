# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'user_settings/profiles/show', feature_category: :user_profile do
  let_it_be(:user_status) { build_stubbed(:user_status, clear_status_at: 8.hours.from_now) }
  let_it_be(:user) { user_status.user }

  before do
    assign(:user, user)
    allow(controller).to receive(:current_user).and_return(user)
    allow(view).to receive(:experiment_enabled?)
    stub_feature_flags(edit_user_profile_vue: false)
    allow(view).to receive(:can?)
  end

  context 'when the profile page is opened' do
    it 'displays the correct elements' do
      render

      expect(rendered).to have_field('user_name', with: user.name)
      expect(rendered).to have_field('user_id', with: user.id)

      expected_link = help_page_path('user/profile/_index.md',
        anchor: 'use-an-automatically-generated-private-commit-email')
      expected_link_html = "<a href=\"#{expected_link}\" target=\"_blank\" " \
                           "rel=\"noopener noreferrer\">#{s_('Profiles|What is a private commit email?')}</a>"

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
        with: user_status.clear_status_at.to_fs(:iso8601),
        type: :hidden
      )
    end

    describe 'private profile', feature_category: :user_management do
      before do
        allow(view).to receive(:can?).with(user, :make_profile_private, user).and_return(true)
      end

      it 'renders correct CE partial' do
        render

        expect(rendered).to render_template('user_settings/profiles/_private_profile')
        expect(rendered).to have_link 'What information is hidden?',
          href: help_page_path('user/profile/_index.md', anchor: 'make-your-user-profile-page-private')
      end
    end
  end
end
