# frozen_string_literal: true

module UserLoginHelper
  def ensure_tab_pane_correctness(visit_path = true)
    if visit_path
      visit new_user_session_path
    end

    ensure_tab_pane_counts
    ensure_one_active_tab
    ensure_one_active_pane
  end

  def ensure_tab_pane_counts
    tabs_count = page.all('[role="tab"]').size
    expect(page).to have_selector('[role="tabpanel"]', count: tabs_count)
  end

  def ensure_one_active_tab
    expect(page).to have_selector('ul.new-session-tabs > li > a.active', count: 1)
  end

  def ensure_one_active_pane
    expect(page).to have_selector('.tab-pane.active', count: 1)
  end
end
