RSpec::Matchers.define :have_emoji do |emoji_name|
  match do |actual|
    expect(actual).to have_selector("gl-emoji[data-name='#{emoji_name}']")
  end
end
