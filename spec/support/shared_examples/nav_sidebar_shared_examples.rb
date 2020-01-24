# frozen_string_literal: true

RSpec.shared_examples 'has nav sidebar' do
  it 'has collapsed nav sidebar on mobile' do
    render

    expect(rendered).to have_selector('.nav-sidebar')
    expect(rendered).not_to have_selector('.sidebar-collapsed-desktop')
    expect(rendered).not_to have_selector('.sidebar-expanded-mobile')
  end
end

RSpec.shared_examples 'page has active tab' do |title|
  it "activates #{title} tab" do
    expect(page).to have_selector('.sidebar-top-level-items > li.active', count: 1)
    expect(find('.sidebar-top-level-items > li.active')).to have_content(title)
  end
end

RSpec.shared_examples 'page has active sub tab' do |title|
  it "activates #{title} sub tab" do
    expect(page).to have_selector('.sidebar-sub-level-items  > li.active:not(.fly-out-top-item)', count: 1)
    expect(find('.sidebar-sub-level-items > li.active:not(.fly-out-top-item)'))
      .to have_content(title)
  end
end
