shared_examples "an autodiscoverable RSS feed with current_user's private token" do
  it "has an RSS autodiscovery link tag with current_user's private token" do
    expect(page).to have_css("link[type*='atom+xml'][href*='private_token=#{Thread.current[:current_user].private_token}']", visible: false)
  end
end

shared_examples "it has an RSS button with current_user's private token" do
  it "shows the RSS button with current_user's private token" do
    expect(page).to have_css("a:has(.fa-rss)[href*='private_token=#{Thread.current[:current_user].private_token}']")
  end
end

shared_examples "an autodiscoverable RSS feed without a private token" do
  it "has an RSS autodiscovery link tag without a private token" do
    expect(page).to have_css("link[type*='atom+xml']:not([href*='private_token'])", visible: false)
  end
end

shared_examples "it has an RSS button without a private token" do
  it "shows the RSS button without a private token" do
    expect(page).to have_css("a:has(.fa-rss):not([href*='private_token'])")
  end
end
