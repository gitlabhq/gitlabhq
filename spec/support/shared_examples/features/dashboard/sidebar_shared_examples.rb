# frozen_string_literal: true

RSpec.shared_examples "a dashboard page with sidebar" do |page_path, menu_label|
  before do
    sign_in(user)
    visit send(page_path)
  end

  let(:sidebar_css) { "aside.nav-sidebar[aria-label=\"Your work\"]" }
  let(:active_menu_item_css) { "li.active[data-track-label=\"#{menu_label}_menu\"]" }

  it "shows the \"Your work\" sidebar" do
    expect(page).to have_css(sidebar_css)
  end

  it "shows the correct sidebar menu item as active" do
    within(sidebar_css) do
      expect(page).to have_css(active_menu_item_css)
    end
  end
end
