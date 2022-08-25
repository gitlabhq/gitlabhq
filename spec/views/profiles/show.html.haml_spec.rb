# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'profiles/show' do
  let(:user) { create(:user) }

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
  end
end
