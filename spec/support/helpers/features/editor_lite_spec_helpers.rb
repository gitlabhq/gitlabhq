# frozen_string_literal: true

# These helpers help you interact within the Editor Lite (single-file editor, snippets, etc.).
#
module Spec
  module Support
    module Helpers
      module Features
        module EditorLiteSpecHelpers
          include ActionView::Helpers::JavaScriptHelper

          def editor_set_value(value)
            editor = find('.monaco-editor')
            uri = editor['data-uri']

            execute_script("monaco.editor.getModel('#{uri}').setValue('#{escape_javascript(value)}')")
          end

          def editor_get_value
            editor = find('.monaco-editor')
            uri = editor['data-uri']

            evaluate_script("monaco.editor.getModel('#{uri}').getValue()")
          end
        end
      end
    end
  end
end
