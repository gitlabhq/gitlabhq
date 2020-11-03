# frozen_string_literal: true

module UserLoginHelper
  def ensure_tab_pane_correctness(tab_names)
    ensure_tab_pane_counts(tab_names.size)
    ensure_tab_labels(tab_names)
    ensure_one_active_tab
    ensure_one_active_pane
  end

  def ensure_no_tabs
    expect(page.all('[role="tab"]').size).to eq(0)
  end

  def ensure_tab_labels(tab_names)
    tab_labels = page.all('[role="tab"]').map(&:text)

    expect(tab_names).to match_array(tab_labels)
  end

  def ensure_tab_pane_counts(tabs_count)
    expect(page.all('[role="tab"]').size).to eq(tabs_count)
    expect(page).to have_selector('[role="tabpanel"]', visible: :all, count: tabs_count)
  end

  def ensure_one_active_tab
    expect(page).to have_selector('ul.new-session-tabs > li > a.active', count: 1)
  end

  def ensure_one_active_pane
    expect(page).to have_selector('.tab-pane.active', count: 1)
  end
end
