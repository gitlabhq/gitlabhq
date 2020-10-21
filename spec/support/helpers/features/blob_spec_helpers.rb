# frozen_string_literal: true

# These helpers help you interact within the blobs page and blobs edit page (Single file editor).
module BlobSpecHelpers
  include ActionView::Helpers::JavaScriptHelper

  def set_default_button(type)
    evaluate_script("localStorage.setItem('gl-web-ide-button-selected', '#{type}')")
  end

  def unset_default_button
    set_default_button('')
  end

  def editor_value
    evaluate_script('monaco.editor.getModels()[0].getValue()')
  end

  def set_editor_value(value)
    execute_script("monaco.editor.getModels()[0].setValue('#{value}')")
  end
end
