shared_examples "an autodiscoverable RSS feed with current_user's feed token" do
  it "has an RSS autodiscovery link tag with current_user's feed token" do
    expect(page).to have_css("link[type*='atom+xml'][href*='feed_token=#{user.feed_token}']", visible: false)
  end
end

shared_examples "it has an RSS button with current_user's feed token" do
  it "shows the RSS button with current_user's feed token" do
    expect(page).to have_css("a:has(.fa-rss)[href*='feed_token=#{user.feed_token}']")
  end
end

shared_examples "an autodiscoverable RSS feed without a feed token" do
  it "has an RSS autodiscovery link tag without a feed token" do
    expect(page).to have_css("link[type*='atom+xml']:not([href*='feed_token'])", visible: false)
  end
end

shared_examples "it has an RSS button without a feed token" do
  it "shows the RSS button without a feed token" do
    expect(page).to have_css("a:has(.fa-rss):not([href*='feed_token'])")
  end
end
