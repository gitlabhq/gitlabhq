# frozen_string_literal: true

RSpec.shared_examples 'verified navigation bar' do
  let(:expected_structure) do
    structure.compact!
    structure.each { |s| s[:nav_sub_items]&.compact! }
    structure
  end

  it 'renders correctly' do
    section = page.find('[data-testid="non-static-items-section"]')
    current_structure = section.all('& > li', wait: false).map do |item|
      nav_sub_items = item.all('li', visible: :all, wait: false).map do |list_item|
        link = list_item.all('a', visible: :all, wait: false).first
        text = link.text(:all)

        # Remove counts and badges in navigation
        badge_text = link.all('[data-testid="nav-item-feature-announcement-badge"]', visible: :all,
          wait: false).first&.text(:all)
        text = text.gsub(badge_text, '').strip if badge_text.present?
        text.gsub(/\s+\d+$/, '')
      end

      { nav_item: item.text, nav_sub_items: nav_sub_items }
    end.compact

    expect(current_structure).to eq(expected_structure)
  end
end
