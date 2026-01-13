# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/integrations/slack_slash_commands_deprecation_alert', feature_category: :integrations do
  it 'renders' do
    render 'shared/integrations/slack_slash_commands_deprecation_alert'

    expect(rendered).to have_text(
      'Slack slash commands integration will be removed in GitLab 19.0.'
    )
  end
end
