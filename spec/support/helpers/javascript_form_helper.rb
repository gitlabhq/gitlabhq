# frozen_string_literal: true

module JavascriptFormHelper
  def prevent_submit_for(query_selector)
    execute_script("document.querySelector('#{query_selector}').addEventListener('submit', e => e.preventDefault())")
  end
end
