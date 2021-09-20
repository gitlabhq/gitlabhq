# frozen_string_literal: true

RSpec.shared_examples "an authenticated issuable atom feed" do
  it "renders atom feed with common issuable information" do
    expect(response_headers['Content-Type'])
      .to have_content('application/atom+xml')
    expect(body).to have_selector('author email', text: issuable.author_public_email)
    expect(body).to have_selector('assignees assignee email', text: issuable.assignees.first.public_email)
    expect(body).to have_selector('assignee email', text: issuable.assignees.first.public_email)
    expect(body).to have_selector('entry summary', text: issuable.title)
  end
end
