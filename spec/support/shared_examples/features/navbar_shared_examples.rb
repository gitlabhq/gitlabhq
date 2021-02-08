# frozen_string_literal: true

RSpec.shared_examples 'verified navigation bar' do
  let(:expected_structure) do
    structure.compact!
    structure.each { |s| s[:nav_sub_items]&.compact! }
    structure
  end

  it 'renders correctly' do
    # we are using * here in the selectors to prevent a regression where we added a non 'li' inside an 'ul'
    current_structure = page.all('.sidebar-top-level-items > *', class: ['!hidden']).map do |item|
      next if item.find_all('a').empty?

      nav_item = item.find_all('a').first.text.gsub(/\s+\d+$/, '') # remove counts at the end

      nav_sub_items = item.all('.sidebar-sub-level-items > *', class: ['!fly-out-top-item']).map do |list_item|
        list_item.all('a').first.text
      end

      { nav_item: nav_item, nav_sub_items: nav_sub_items }
    end.compact

    expect(current_structure).to eq(expected_structure)
  end
end
