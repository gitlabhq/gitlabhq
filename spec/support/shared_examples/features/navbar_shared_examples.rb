# frozen_string_literal: true

RSpec.shared_examples 'verified navigation bar' do
  let(:expected_structure) do
    structure.compact!
    structure.each { |s| s[:nav_sub_items]&.compact! }
    structure
  end

  it 'renders correctly' do
    # The sidebar is a client-rendered Vue app. Wait for it to finish rendering
    # by asserting on stable, expected end-state signals *before* reading the DOM
    # with `wait: false` below. Reading an unsettled tree captures items that have
    # not mounted yet (or transient extras/badges), which is the source of the
    # flakiness. See https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/43248
    expect(page).to have_testid('non-static-items-section')

    section = find_by_testid('non-static-items-section')

    # Wait for every top-level item to be present (waiting matcher), then confirm
    # the last expected item's label has rendered. Together these prove the
    # single-shot render has settled before the fast `wait: false` reads.
    expect(section).to have_selector('& > li', count: expected_structure.size)
    expect(section).to have_content(expected_structure.last[:nav_item]) if expected_structure.any?

    current_structure = section.all('& > li', wait: false).map do |item|
      nav_sub_items = item.all('li', visible: :all, wait: false).map do |list_item|
        link = list_item.all('a', visible: :all, wait: false).first
        text = link.text(:all)

        # Remove counts and badges in navigation
        badge_text = all_by_testid('nav-item-feature-announcement-badge', context: link, visible: :all,
          wait: false).first&.text(:all)
        text = text.gsub(badge_text, '').strip if badge_text.present?
        text.gsub(/\s+(?:\d+|-)$/, '')
      end

      { nav_item: item.text, nav_sub_items: nav_sub_items }
    end.compact

    expect(current_structure).to eq(expected_structure)
  end
end
