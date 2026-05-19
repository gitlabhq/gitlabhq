# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe 'notify/new_achievement_email.html.haml', feature_category: :user_profile do
  let(:user) { build(:user) }
  let(:achievement) { build(:achievement) }

  before do
    allow(view).to receive(:message) { instance_double(Mail::Message, subject: 'Subject') }
    assign(:user, user)
    assign(:achievement, achievement)
    assign(:accept_url, 'https://gitlab.com/-/awarded_achievements/token123/accept')
  end

  it 'contains achievement information' do
    render

    expect(rendered).to have_content(achievement.namespace.full_path)
    expect(rendered).to have_content(" awarded you the ")
    expect(rendered).to have_content(achievement.name)
    expect(rendered).to have_content(" achievement!")
  end

  it 'contains the accept link and ignore message' do
    render

    expect(rendered).to have_content('Accept')
    expect(rendered).to have_content('simply ignore this email')
  end

  context 'when achievement name contains HTML' do
    let(:achievement) { build(:achievement, name: '<script>alert(1)</script>') }

    it 'renders the achievement name as text, not HTML', :skip_html_escaped_tags_check do
      render

      expect(rendered).to have_content('<script>alert(1)</script>')
      expect(rendered).to have_no_selector('script')
    end
  end
end
