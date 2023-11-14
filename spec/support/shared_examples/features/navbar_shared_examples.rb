# frozen_string_literal: true

RSpec.shared_examples 'verified navigation bar' do
  let(:expected_structure) do
    structure.compact!
    structure.each { |s| s[:nav_sub_items]&.compact! }
    structure
  end

  it 'renders correctly' do
    current_structure = page.all('[data-testid="non-static-items-section"] > li').map do |item|
      nav_sub_items = item.all('li', visible: :all).map do |list_item|
        list_item.all('a', visible: :all).first.text(:all).gsub(/\s+\d+$/, '') # remove counts at the end
      end

      { nav_item: item.text, nav_sub_items: nav_sub_items }
    end.compact

    expect(current_structure).to eq(expected_structure)
  end
end
