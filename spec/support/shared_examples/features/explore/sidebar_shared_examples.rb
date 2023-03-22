# frozen_string_literal: true

RSpec.shared_examples 'an "Explore" page with sidebar and breadcrumbs' do |page_path, menu_label|
  before do
    visit send(page_path)
  end

  let(:sidebar_css) { 'aside.nav-sidebar[aria-label="Explore"]' }
  let(:active_menu_item_css) { "li.active[data-track-label=\"#{menu_label}_menu\"]" }

  it 'shows the "Explore" sidebar' do
    expect(page).to have_css(sidebar_css)
  end

  it 'shows the correct sidebar menu item as active' do
    within(sidebar_css) do
      expect(page).to have_css(active_menu_item_css)
    end
  end

  describe 'breadcrumbs' do
    it 'has "Explore" as its root breadcrumb' do
      within '.breadcrumbs-list' do
        expect(page).to have_css("li:first a[href=\"#{explore_root_path}\"]", text: 'Explore')
      end
    end
  end
end
