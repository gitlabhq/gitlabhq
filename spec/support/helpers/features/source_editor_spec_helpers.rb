# frozen_string_literal: true

# These helpers help you interact within the Source Editor (single-file editor, snippets, etc.).
#
module Spec
  module Support
    module Helpers
      module Features
        module SourceEditorSpecHelpers
          include ActionView::Helpers::JavaScriptHelper

          def editor_set_value(value)
            editor = find('.monaco-editor')
            uri = editor['data-uri']
            execute_script("localMonaco.getModel('#{uri}').setValue('#{escape_javascript(value)}')")
          end
        end
      end
    end
  end
end
