# frozen_string_literal: true

module SelectionHelper
  def select_element(selector)
    find(selector)
    execute_script("let sel = window.getSelection(); sel.removeAllRanges(); let range = document.createRange(); range.selectNodeContents(document.querySelector('#{selector}')); sel.addRange(range);")
  end
end
