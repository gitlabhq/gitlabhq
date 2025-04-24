# frozen_string_literal: true

module RapidDiffsHelpers
  def select_inline_view
    open_diff_view_preferences
    inline_view_option.click
  end

  def select_parallel_view
    open_diff_view_preferences
    parallel_view_option.click
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
end
