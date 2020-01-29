# frozen_string_literal: true

RSpec.shared_examples 'verified navigation bar' do
  it 'renders correctly' do
    current_structure = page.find_all('.sidebar-top-level-items > li', class: ['!hidden']).map do |item|
      nav_item = item.find_all('a').first.text.gsub(/\s+\d+$/, '') # remove counts at the end

      nav_sub_items = item
        .find_all('.sidebar-sub-level-items a')
        .map(&:text)
        .drop(1) # remove the first hidden item

      { nav_item: nav_item, nav_sub_items: nav_sub_items }
    end

    structure.each { |s| s[:nav_sub_items].compact! }

    expect(current_structure).to eq(structure)
  end
end
