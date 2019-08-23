# frozen_string_literal: true

module DragTo
  def drag_to(list_from_index: 0, from_index: 0, to_index: 0, list_to_index: 0, selector: '', scrollable: 'body', duration: 1000, perform_drop: true)
    js = <<~JS
      simulateDrag({
        scrollable: document.querySelector('#{scrollable}'),
        duration: #{duration},
        from: {
          el: document.querySelectorAll('#{selector}')[#{list_from_index}],
          index: #{from_index}
        },
        to: {
          el: document.querySelectorAll('#{selector}')[#{list_to_index}],
          index: #{to_index}
        },
        performDrop: #{perform_drop}
      });
    JS
    evaluate_script(js)

    Timeout.timeout(Capybara.default_max_wait_time) do
      loop while drag_active?
    end
  end

  def drag_active?
    page.evaluate_script('window.SIMULATE_DRAG_ACTIVE').nonzero?
  end
end
