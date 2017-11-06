# see app/assets/javascripts/test_utils/simulate_input.js

module InputHelper
  def simulate_input(selector, input = '')
    evaluate_script("window.simulateInput(#{selector.to_json}, #{input.to_json});")
  end
end
