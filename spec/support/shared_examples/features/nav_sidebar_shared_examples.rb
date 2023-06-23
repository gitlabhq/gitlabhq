# frozen_string_literal: true

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
