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

RSpec.shared_examples "a sanitized issuable atom feed" do
  it "sanitizes HTML in the description" do
    expect(body).to have_selector('entry content[type="html"]', text: 'Legitimate text')
    expect(body).not_to include('<style>')
    expect(body).not_to include('<script>')
  end

  it "renders the title as sanitized HTML" do
    expect(body).to have_selector('entry title[type="html"]', text: issuable.title)
    expect(body).not_to include('<script>')
  end

  it "XML-escapes the rendered HTML for Atom transport" do
    # With type="html", the builder XML-escapes the rendered HTML:
    #
    #   <content type="html">&lt;p ...&gt;...&lt;/p&gt;</content>
    #
    # i.e. the *textual* content of the <content> tag is '<p ...> ... </p>'.
    #
    # If the HTML were inserted raw, <p> would be a child element and never
    # appear as text, so seeing '<p' in the text shows correct escaping.
    expect(body).to have_selector('entry content[type="html"]', text: '<p')

    # Conversely, there must be no actual <p> element in the XML DOM.
    expect(body).not_to have_selector('entry content p')
  end
end
