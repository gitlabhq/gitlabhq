# frozen_string_literal: true

# These helpers help you interact within the Editor Lite (single-file editor, snippets, etc.).
#
module Spec
  module Support
    module Helpers
      module Features
        module SnippetSpecHelpers
          include ActionView::Helpers::JavaScriptHelper
          include Spec::Support::Helpers::Features::EditorLiteSpecHelpers

          def snippet_get_first_blob_path
            page.find_field(snippet_blob_path_field, match: :first).value
          end

          def snippet_get_first_blob_value
            page.find(snippet_blob_content_selector, match: :first)
          end

          def snippet_description_value
            page.find_field(snippet_description_field).value
          end

          def snippet_fill_in_form(title:, content:, description: '')
            # fill_in snippet_title_field, with: title
            # editor_set_value(content)
            fill_in snippet_title_field, with: title

            if description
              # Click placeholder first to expand full description field
              description_field.click
              fill_in snippet_description_field, with: description
            end

            page.within('.file-editor') do
              el = find('.inputarea')
              el.send_keys content
            end
          end

          private

          def description_field
            find('.js-description-input').find('input,textarea')
          end
        end
      end
    end
  end
end
