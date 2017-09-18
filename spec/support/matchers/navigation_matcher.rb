RSpec::Matchers.define :have_active_navigation do |expected|
  match do |page|
    expect(page).to have_selector('.sidebar-top-level-items > li.active', count: 1)
    expect(page.find('.sidebar-top-level-items > li.active')).to have_content(expected)
  end
end
