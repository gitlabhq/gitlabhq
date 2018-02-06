RSpec::Matchers.define :have_active_navigation do |expected|
  match do |page|
    expect(page).to have_selector('.sidebar-top-level-items > li.active', count: 1)
    expect(page.find('.sidebar-top-level-items > li.active')).to have_content(expected)
  end
end

RSpec::Matchers.define :have_active_sub_navigation do |expected|
  match do |page|
    expect(page.find('.sidebar-sub-level-items > li.active:not(.fly-out-top-item)')).to have_content(expected)
  end
end
