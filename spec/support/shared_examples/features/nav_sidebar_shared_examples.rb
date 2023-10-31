# frozen_string_literal: true

RSpec.shared_examples 'page has active tab' do |title|
  it "activates #{title} tab" do
    within_testid('super-sidebar') do
      expect(page).to have_selector('button[aria-expanded="true"]', text: title)
    end
  end
end

RSpec.shared_examples 'page has active sub tab' do |title|
  it "activates #{title} sub tab" do
    within_testid('super-sidebar') do
      expect(page).to have_selector('a[aria-current="page"]', text: title)
    end
  end
end
