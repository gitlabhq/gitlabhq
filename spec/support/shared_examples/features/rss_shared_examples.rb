# frozen_string_literal: true

RSpec.shared_examples "an autodiscoverable RSS feed with current_user's feed token" do
  it "has an RSS autodiscovery link tag with current_user's feed token" do
    expect(page).to have_css("link[type*='atom+xml'][href*='feed_token=glft-'][href*='-#{user.id}']", visible: false)
  end
end

RSpec.shared_examples "it has an RSS button with current_user's feed token" do
  it "shows the RSS button with current_user's feed token" do
    expect(page)
      .to have_css("a:has([data-testid='rss-icon'])[href*='feed_token=glft-'][href*='-#{user.id}']")
  end
end

RSpec.shared_examples "it has an RSS link with current_user's feed token" do
  it "shows the RSS link with current_user's feed token" do
    expect(page).to have_link 'Subscribe to RSS feed', href: /feed_token=glft-.*-#{user.id}/
  end
end

RSpec.shared_examples "an autodiscoverable RSS feed without a feed token" do
  it "has an RSS autodiscovery link tag without a feed token" do
    expect(page).to have_css("link[type*='atom+xml']:not([href*='feed_token'])", visible: false)
  end
end

RSpec.shared_examples "it has an RSS button without a feed token" do
  it "shows the RSS button without a feed token" do
    expect(page)
      .to have_css("a:has([data-testid='rss-icon']):not([href*='feed_token'])")
  end
end

RSpec.shared_examples "it has an RSS link without a feed token" do
  it "shows the RSS link without a feed token" do
    expect(page).to have_link 'Subscribe to RSS feed'
    expect(page).not_to have_link 'Subscribe to RSS feed', href: /feed_token/
  end
end

RSpec.shared_examples "updates atom feed link" do |type|
  it "for #{type}", :js do
    sign_in(user)
    visit path
    click_button 'Actions', match: :first

    link = find_link('Subscribe to RSS feed')
    params = CGI.parse(URI.parse(link[:href]).query)
    auto_discovery_link = find("link[type='application/atom+xml']", visible: false)
    auto_discovery_params = CGI.parse(URI.parse(auto_discovery_link[:href]).query)

    expected = {
      'assignee_id' => [user.id.to_s]
    }

    expect(params).to include(expected)
    feed_token_param = params['feed_token']
    expect(feed_token_param).to match([Gitlab::Auth::AuthFinders::PATH_DEPENDENT_FEED_TOKEN_REGEX])
    expect(feed_token_param.first).to end_with(user.id.to_s)

    expect(auto_discovery_params).to include(expected)
    feed_token_param = auto_discovery_params['feed_token']
    expect(feed_token_param).to match([Gitlab::Auth::AuthFinders::PATH_DEPENDENT_FEED_TOKEN_REGEX])
    expect(feed_token_param.first).to end_with(user.id.to_s)
  end
end
