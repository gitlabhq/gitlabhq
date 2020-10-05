# frozen_string_literal: true

module DragTo
  # rubocop:disable Metrics/ParameterLists
  def drag_to(list_from_index: 0, from_index: 0, to_index: 0, list_to_index: 0, selector: '', scrollable: 'body', duration: 1000, perform_drop: true, extra_height: 0)
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
        performDrop: #{perform_drop},
        extraHeight: #{extra_height}
      });
    JS
    evaluate_script(js)

    Timeout.timeout(Capybara.default_max_wait_time) do
      loop while drag_active?
    end
  end
  # rubocop:enable Metrics/ParameterLists

  def drag_active?
    page.evaluate_script('window.SIMULATE_DRAG_ACTIVE').nonzero?
  end
end
