# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'notify/change_in_merge_request_draft_status_email.text.erb' do
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request) }

  before do
    assign(:updated_by_user, user)
    assign(:merge_request, merge_request)
  end

  it_behaves_like 'renders plain text email correctly'

  it 'shows user added draft status on email' do
    merge_request.update!(title: merge_request.draft_title)

    render

    expect(merge_request.draft).to be_truthy
    expect(rendered).to have_content("#{user.name} marked merge request #{merge_request.to_reference} as draft")
  end

  it 'shows user removed draft status on email' do
    render

    expect(merge_request.draft).to be_falsy
    expect(rendered).to have_content("#{user.name} marked merge request #{merge_request.to_reference} as ready")
  end
end
