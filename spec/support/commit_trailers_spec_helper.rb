module CommitTrailersSpecHelper
  extend ActiveSupport::Concern

  def expect_to_have_user_link_with_avatar(doc, user:, trailer:, email: nil)
    wrapper = find_user_wrapper(doc, trailer)

    expect_to_have_links_with_url_and_avatar(wrapper, urls.user_url(user), email || user.email)
    expect(wrapper.attribute('data-user').value).to eq user.id.to_s
  end

  def expect_to_have_mailto_link(doc, email:, trailer:)
    wrapper = find_user_wrapper(doc, trailer)

    expect_to_have_links_with_url_and_avatar(wrapper, "mailto:#{CGI.escape_html(email)}", email)
  end

  def expect_to_have_links_with_url_and_avatar(doc, url, email)
    expect(doc).not_to be_nil
    expect(doc.xpath("a[position()<3 and @href='#{url}']").size).to eq 2
    expect(doc.xpath("a[position()=3 and @href='mailto:#{CGI.escape_html(email)}']").size).to eq 1
    expect(doc.css('img').size).to eq 1
  end

  def find_user_wrapper(doc, trailer)
    doc.xpath("descendant-or-self::node()[@data-trailer='#{trailer}']").first
  end

  def build_commit_message(trailer:, name:, email:)
    message = trailer_line(trailer, name, email)

    [message, commit_html(message)]
  end

  def trailer_line(trailer, name, email)
    "#{trailer} #{name} <#{email}>"
  end

  def commit_html(message)
    "<pre>#{CGI.escape_html(message)}</pre>"
  end
end
