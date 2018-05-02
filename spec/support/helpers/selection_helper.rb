module SelectionHelper
  def select_element(selector)
    find(selector)
    execute_script("let range = document.createRange(); let sel = window.getSelection(); range.selectNodeContents(document.querySelector('#{selector}')); sel.addRange(range);")
  end
end
