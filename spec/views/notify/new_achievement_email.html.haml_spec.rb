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
  end

  it 'contains achievement information' do
    render

    expect(rendered).to have_content(achievement.namespace.full_path)
    expect(rendered).to have_content(" awarded you the ")
    expect(rendered).to have_content(achievement.name)
    expect(rendered).to have_content(" achievement!")

    expect(rendered).to have_content("View your achievements on your profile")
  end
end
