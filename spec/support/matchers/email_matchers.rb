RSpec::Matchers.define :have_html_escaped_body_text do |expected|
  match do |actual|
    expect(actual).to have_body_text(ERB::Util.html_escape(expected))
  end
end
