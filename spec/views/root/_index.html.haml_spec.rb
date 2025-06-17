# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'root/index.html.haml', feature_category: :onboarding do
  let_it_be(:mock_review_requested_path) { "review_requested_path" }
  let_it_be(:mock_assigned_to_you_path) { "assigned_to_you_path" }

  before do
    @homepage_app_data = {
      review_requested_path: mock_review_requested_path,
      assigned_to_you_path: mock_assigned_to_you_path
    }
    render
  end

  it 'renders the app root element with the correct data attributes' do
    expect(rendered).to have_css("[data-review-requested-path='#{mock_review_requested_path}']")
    expect(rendered).to have_css("[data-assigned-to-you-path='#{mock_assigned_to_you_path}']")
  end
end
