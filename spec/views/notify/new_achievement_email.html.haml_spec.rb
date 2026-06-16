# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe 'notify/new_achievement_email.html.haml', feature_category: :user_profile do
  let(:user) { build(:user) }
  let(:achievement) { build(:achievement) }
  let(:user_achievement) { build(:user_achievement, user: user, achievement: achievement) }

  before do
    allow(view).to receive(:message) { instance_double(Mail::Message, subject: 'Subject') }
    assign(:user, user)
    assign(:achievement, achievement)
    assign(:user_achievement, user_achievement)
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

  context 'when award message is present' do
    let(:user_achievement) do
      build(:user_achievement, user: user, achievement: achievement,
        award_message: 'Great contribution', award_message_html: '<p>Great contribution</p>')
    end

    it 'includes the award message' do
      render

      expect(rendered).to have_content('Great contribution')
    end
  end

  context 'when award message is blank' do
    let(:user_achievement) do
      build(:user_achievement, user: user, achievement: achievement,
        award_message: nil, award_message_html: nil)
    end

    it 'does not render the award message' do
      render

      expect(rendered).to have_no_content('Great contribution')
    end
  end

  context 'when award message contains HTML' do
    let(:user_achievement) do
      build(:user_achievement, user: user, achievement: achievement,
        award_message: '<script>alert(1)</script>')
    end

    it 'does not render raw HTML tags', :skip_html_escaped_tags_check do
      render

      expect(rendered).to have_no_selector('script')
    end
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
