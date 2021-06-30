# frozen_string_literal: true

# These helpers help you interact within the Source Editor (single-file editor, snippets, etc.).
#

require Rails.root.join("spec/support/helpers/features/source_editor_spec_helpers.rb")

module Spec
  module Support
    module Helpers
      module Features
        module SnippetSpecHelpers
          include ActionView::Helpers::JavaScriptHelper
          include Spec::Support::Helpers::Features::SourceEditorSpecHelpers

          def snippet_description_locator
            'snippet-description'
          end

          def snippet_blob_path_locator
            'snippet_file_name'
          end

          def snippet_description_view_selector
            '.snippet-header .snippet-description'
          end

          def snippet_description_field_collapsed
            find('.js-description-input').find('input,textarea')
          end

          def snippet_get_first_blob_path
            page.find_field('snippet_file_name', match: :first).value
          end

          def snippet_get_first_blob_value
            page.find('.gl-source-editor', match: :first)
          end

          def snippet_description_value
            page.find_field(snippet_description_locator).value
          end

          def snippet_fill_in_visibility(text)
            page.find('#visibility-level-setting').choose(text)
          end

          def snippet_fill_in_title(value)
            fill_in 'snippet-title', with: value
          end

          def snippet_fill_in_description(value)
            # Click placeholder first to expand full description field
            snippet_description_field_collapsed.click
            fill_in snippet_description_locator, with: value
          end

          def snippet_fill_in_content(value)
            page.within('.gl-source-editor') do
              el = find('.inputarea')
              el.send_keys value
            end
          end

          def snippet_fill_in_file_name(value)
            fill_in(snippet_blob_path_locator, match: :first, with: value)
          end

          def snippet_fill_in_form(title: nil, content: nil, file_name: nil, description: nil, visibility: nil)
            snippet_fill_in_title(title) if title

            snippet_fill_in_description(description) if description

            snippet_fill_in_file_name(file_name) if file_name

            snippet_fill_in_content(content) if content

            snippet_fill_in_visibility(visibility) if visibility
          end
        end
      end
    end
  end
end
