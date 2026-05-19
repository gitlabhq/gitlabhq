# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'achievements/awarded_achievements/_confirmation.html.haml', feature_category: :user_profile do
  let(:user) { build_stubbed(:user) }
  let(:achievement) { build_stubbed(:achievement, name: 'Great Contribution') }
  let(:user_achievement) { build_stubbed(:user_achievement, user: user, achievement: achievement) }

  before do
    assign(:user_achievement, user_achievement)
    description_text = s_(
      "Achievements|Are you sure you want to accept the %{bold_start}%{achievement_name}%{bold_end} achievement? " \
        "It will be shown on your profile."
    )
    render partial: 'achievements/awarded_achievements/confirmation', locals: {
      title: s_("Achievements|Accept achievement"),
      description: description_text,
      action_url: '/-/awarded_achievements/test-token/accept?force=true',
      button_variant: :confirm,
      button_text: s_("Achievements|Accept")
    }
  end

  it 'contains confirmation content' do
    expect(rendered).to have_content('Accept achievement')
    expect(rendered).to have_content('Great Contribution')
    expect(rendered).to have_content('Cancel')
  end

  context 'when achievement name contains HTML' do
    let(:achievement) { build_stubbed(:achievement, name: '<script>alert("xss")</script>') }

    it 'escapes the achievement name', :skip_html_escaped_tags_check do
      expect(rendered).not_to include('<script>alert("xss")</script>')
      expect(rendered).to have_content('<script>alert("xss")</script>')
    end
  end
end
