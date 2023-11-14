# frozen_string_literal: true

RSpec.shared_examples 'a "Your work" page with sidebar and breadcrumbs' do |page_path, menu_label|
  before do
    sign_in(user)
    visit send(page_path)
  end

  it "shows the \"Your work\" sidebar" do
    expect(page).to have_css('#super-sidebar-context-header', text: 'Your work')
  end

  it "shows the correct sidebar menu item as active" do
    within_testid('super-sidebar') do
      expect(page).to have_css("a[data-track-label='#{menu_label}_menu'][aria-current='page']")
    end
  end

  describe "breadcrumbs" do
    it 'has "Your work" as its root breadcrumb' do
      within_testid('breadcrumb-links') do
        expect(page).to have_css("li:first-child a[href=\"#{root_path}\"]", text: "Your work")
      end
    end
  end
end
