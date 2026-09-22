# frozen_string_literal: true

module RapidDiffsHelpers
  def diff_file(path)
    header = XPath.descendant(:header).descendant(:h2)[XPath.string.n == path]
    find(:xpath, XPath.descendant(:'diff-file')[header], match: :first)
  end

  def within_diff_file(path, &block)
    within(diff_file(path), &block)
  end

  def diff_line(text, within: nil)
    scope = within ? diff_file(within) : page
    scope.find('[data-hunk-lines]', text: text, match: :first)
  end

  def scroll_to_center(element)
    page.execute_script("arguments[0].scrollIntoView({ block: 'center' })", element.native)
  end

  def select_inline_view
    switch_diff_view('hunk-lines-inline') { inline_view_option.click }
  end

  def select_parallel_view
    switch_diff_view('hunk-lines-parallel') { parallel_view_option.click }
  end

  def switch_diff_view(rendered_testid)
    open_diff_view_preferences
    yield

    page.assert_selector("[data-testid='#{rendered_testid}']")
  end

  def inline_view_option
    find('[role="option"]', text: 'Inline')
  end

  def parallel_view_option
    find('[role="option"]', text: 'Side-by-side')
  end

  def open_diff_view_preferences
    button = find("button:has(svg[data-testid='preferences-icon'])")
    return if button['aria-expanded'] == 'true'

    button.click
  end

  def close_diff_view_preferences
    button = find("button:has(svg[data-testid='preferences-icon'])")
    return unless button['aria-expanded'] == 'true'

    button.click
  end

  # Activates the new-discussion toggle on a Rapid Diffs row. Hovers the
  # row's line-number link until the toggle actually lands inside the row,
  # then clicks it. Retrying the hover guards against the toggle controller
  # not having attached its listeners yet -- the first hover can be dropped
  # silently if the rapid-diffs init has not finished. The retry is what a
  # human would do when nothing happens on first move.
  def click_rapid_diffs_line(row_selector)
    row = find(row_selector)
    page.execute_script("arguments[0].scrollIntoView({ block: 'center' })", row.native)
    link = row.find('[data-line-number]', match: :first)
    wait_for('new-discussion toggle to appear on the row') do
      link.hover
      has_testid?('new_discussion_toggle', context: row, wait: 0.2)
    end
    find_by_testid('new_discussion_toggle', context: row).click
  end
end
