shared_examples "an autodiscoverable RSS feed with current_user's rss token" do
  it "has an RSS autodiscovery link tag with current_user's rss token" do
    expect(page).to have_css("link[type*='atom+xml'][href*='rss_token=#{Thread.current[:current_user].rss_token}']", visible: false)
  end
end

shared_examples "it has an RSS button with current_user's rss token" do
  it "shows the RSS button with current_user's rss token" do
    expect(page).to have_css("a:has(.fa-rss)[href*='rss_token=#{Thread.current[:current_user].rss_token}']")
  end
end

shared_examples "an autodiscoverable RSS feed without an rss token" do
  it "has an RSS autodiscovery link tag without an rss token" do
    expect(page).to have_css("link[type*='atom+xml']:not([href*='rss_token'])", visible: false)
  end
end

shared_examples "it has an RSS button without an rss token" do
  it "shows the RSS button without an rss token" do
    expect(page).to have_css("a:has(.fa-rss):not([href*='rss_token'])")
  end
end
