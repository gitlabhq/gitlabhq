module JsPatch
  def confirm_js_popup
    page.evaluate_script("window.alert = function(msg) { return true; }")
    page.evaluate_script("window.confirm = function(msg) { return true; }")
  end
end
