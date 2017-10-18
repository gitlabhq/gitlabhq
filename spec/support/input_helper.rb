# see app/assets/javascripts/test_utils/simulate_input.js

module InputHelper
  def simulateInput(selector, input = '')
    evaluate_script("window.simulateInput(#{selector.to_json}, #{input.to_json});")
  end
end
  