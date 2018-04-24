module BoardHelpers
  def click_card(card)
    within card do
      first('.board-card-number').click
    end

    wait_for_sidebar
  end

  def wait_for_sidebar
    # loop until the CSS transition is complete
    Timeout.timeout(0.5) do
      loop until evaluate_script('$(".right-sidebar").outerWidth()') == 290
    end
  end
end
