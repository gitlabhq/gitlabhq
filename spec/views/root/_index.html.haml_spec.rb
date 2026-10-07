# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'root/index.html.haml', feature_category: :onboarding do
  let_it_be(:mock_activity_path) { "activity_path" }
  let_it_be(:mock_last_push_event) { '{"branch_name":"feature-branch"}' }

  before do
    @homepage_app_data = {
      activity_path: mock_activity_path,
      last_push_event: mock_last_push_event
    }
    allow(view).to receive_messages(user_groups_requiring_reauth: [])
    render
  end

  it 'renders the app root element with the correct data attributes' do
    expect(rendered).to have_css("[data-activity-path='#{mock_activity_path}']")
    expect(rendered).to have_css("[data-last-push-event='#{mock_last_push_event}']")
  end
end
