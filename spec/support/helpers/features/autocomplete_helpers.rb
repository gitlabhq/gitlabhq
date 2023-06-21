# frozen_string_literal: true

module Features
  module AutocompleteHelpers
    def find_autocomplete_menu
      find('.atwho-view ul', visible: true)
    end

    def find_highlighted_autocomplete_item
      find('.atwho-view li.cur', visible: true)
    end
  end
end
