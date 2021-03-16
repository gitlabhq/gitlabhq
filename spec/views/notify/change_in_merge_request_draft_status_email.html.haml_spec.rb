# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'notify/change_in_merge_request_draft_status_email.html.haml' do
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request) }

  before do
    assign(:updated_by_user, user)
    assign(:merge_request, merge_request)
  end

  it 'renders the email correctly' do
    render

    expect(rendered).to have_content("#{user.name} changed the draft status of merge request #{merge_request.to_reference}")
  end
end
