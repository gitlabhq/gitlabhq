# frozen_string_literal: true

# These helpers help you interact within the Source Editor (single-file editor, snippets, etc.).
#
module Features
  module SourceEditorSpecHelpers
    include ActionView::Helpers::JavaScriptHelper

    def editor_set_value(value)
      editor = find('.monaco-editor')
      uri = editor['data-uri']
      execute_script("localMonaco.getModel('#{uri}').setValue('#{escape_javascript(value)}')")

      # We only check that the first line is present because when the content is long,
      # only a part of the text will be rendered in the DOM due to scrolling
      page.has_selector?('.gl-source-editor .view-lines', text: value.lines.first)
    end
  end
end
