# frozen_string_literal: true

module ListboxInputHelper
  include WaitForRequests

  def listbox_input(value, from:)
    open_listbox_input(from) do
      find('[role="option"]', text: value).click
    end
  end

  def listbox_input_value(value, from:)
    open_listbox_input(from) do
      find("[role='option'][data-testid='listbox-item-#{value}']").click
    end
  end

  def open_listbox_input(selector)
    page.within(selector) do
      page.find('button[aria-haspopup="listbox"]').click
      yield
    end
  end
end
