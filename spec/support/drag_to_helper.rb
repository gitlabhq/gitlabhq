module DragTo
  def drag_to(list_from_index: 0, from_index: 0, to_index: 0, list_to_index: 0, selector: '', scrollable: 'body')
    evaluate_script("simulateDrag({scrollable: $('#{scrollable}').get(0), from: {el: $('#{selector}').eq(#{list_from_index}).get(0), index: #{from_index}}, to: {el: $('#{selector}').eq(#{list_to_index}).get(0), index: #{to_index}}});")

    Timeout.timeout(Capybara.default_max_wait_time) do
      loop while drag_active?
    end
  end

  def drag_active?
    page.evaluate_script('window.SIMULATE_DRAG_ACTIVE').nonzero?
  end
end
