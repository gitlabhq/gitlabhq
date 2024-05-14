# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'rich text editor - links' do
  include RichTextEditorHelpers

  describe 'creating and editing links' do
    before do
      switch_to_content_editor
    end

    context 'when clicking the link icon in the toolbar' do
      it 'shows the link bubble menu' do
        page.find('[data-testid="formatting-toolbar"] [data-testid="link"]').click

        expect(page).to have_css('[data-testid="link-bubble-menu"]')
      end

      context 'if no text is selected' do
        before do
          page.find('[data-testid="formatting-toolbar"] [data-testid="link"]').click
        end

        it 'opens an empty inline modal to create a link' do
          page.within '[data-testid="link-bubble-menu"]' do
            expect(page).to have_field('link-text', with: '')
            expect(page).to have_field('link-href', with: '')
          end
        end

        context 'when the user clicks the apply button' do
          it 'applies the changes to the document' do
            page.within '[data-testid="link-bubble-menu"]' do
              fill_in 'link-text', with: 'Link to GitLab home page'
              fill_in 'link-href', with: 'https://gitlab.com'

              click_button 'Apply'
            end

            page.within content_editor_testid do
              expect(page).to have_css('a[href="https://gitlab.com"]')
              expect(page).to have_text('Link to GitLab home page')
            end
          end
        end

        context 'when the user clicks the cancel button' do
          it 'does not apply the changes to the document' do
            page.within '[data-testid="link-bubble-menu"]' do
              fill_in 'link-text', with: 'Link to GitLab home page'
              fill_in 'link-href', with: 'https://gitlab.com'

              click_button 'Cancel'
            end

            page.within content_editor_testid do
              expect(page).not_to have_css('a')
            end
          end
        end
      end

      context 'if text is selected' do
        before do
          type_in_content_editor 'The quick brown fox jumps over the lazy dog'
          type_in_content_editor [:shift, :left]
          type_in_content_editor [:shift, :left]
          type_in_content_editor [:shift, :left]

          page.find('[data-testid="formatting-toolbar"] [data-testid="link"]').click
        end

        it 'prefills inline modal to create a link' do
          page.within '[data-testid="link-bubble-menu"]' do
            expect(page).to have_field('link-text', with: 'dog')
            expect(page).to have_field('link-href', with: '')
          end
        end

        context 'when the user clicks the apply button' do
          it 'applies the changes to the document' do
            page.within '[data-testid="link-bubble-menu"]' do
              fill_in 'link-text', with: 'new dog'
              fill_in 'link-href', with: 'https://en.wikipedia.org/wiki/Shiba_Inu'

              click_button 'Apply'
            end

            page.within content_editor_testid do
              expect(page).to have_selector('a[href="https://en.wikipedia.org/wiki/Shiba_Inu"]',
                text: 'new dog'
              )
            end
          end
        end
      end
    end

    context 'if cursor is placed on an existing link' do
      before do
        type_in_content_editor 'Link to [GitLab home **page**](https://gitlab.com)'
        type_in_content_editor :left
      end

      it 'prefills inline modal to edit the link' do
        page.within '[data-testid="link-bubble-menu"]' do
          page.find('[data-testid="edit-link"]').click

          expect(page).to have_field('link-text', with: 'GitLab home page')
          expect(page).to have_field('link-href', with: 'https://gitlab.com')
        end
      end

      it 'updates the link attributes if text is not updated' do
        page.within '[data-testid="link-bubble-menu"]' do
          page.find('[data-testid="edit-link"]').click

          fill_in 'link-href', with: 'https://about.gitlab.com'

          click_button 'Apply'
        end

        page.within content_editor_testid do
          expect(page).to have_selector('a[href="https://about.gitlab.com"]')
          expect(page.find('a')).to have_text('GitLab home page')
          expect(page).to have_selector('strong', text: 'page')
        end
      end

      it 'updates the link attributes and text if text is updated' do
        page.within '[data-testid="link-bubble-menu"]' do
          page.find('[data-testid="edit-link"]').click

          fill_in 'link-text', with: 'GitLab about page'
          fill_in 'link-href', with: 'https://about.gitlab.com'

          click_button 'Apply'
        end

        page.within content_editor_testid do
          expect(page).to have_selector('a[href="https://about.gitlab.com"]',
            text: 'GitLab about page'
          )
          expect(page).not_to have_selector('strong')
        end
      end

      it 'does nothing if Cancel is clicked' do
        page.within '[data-testid="link-bubble-menu"]' do
          page.find('[data-testid="edit-link"]').click

          click_button 'Cancel'
        end

        page.within content_editor_testid do
          expect(page).to have_selector('a[href="https://gitlab.com"]',
            text: 'GitLab home page'
          )
          expect(page).to have_selector('strong')
        end
      end

      context 'when the user clicks the unlink button' do
        it 'removes the link' do
          page.within '[data-testid="link-bubble-menu"]' do
            page.find('[data-testid="remove-link"]').click
          end

          page.within content_editor_testid do
            expect(page).not_to have_selector('a')
            expect(page).to have_selector('strong', text: 'page')
          end
        end
      end
    end

    context 'when selection spans more than a link' do
      before do
        type_in_content_editor 'a [b **c**](https://gitlab.com)'

        type_in_content_editor [:shift, :left]
        type_in_content_editor [:shift, :left]
        type_in_content_editor [:shift, :left]
        type_in_content_editor [:shift, :left]
        type_in_content_editor [:shift, :left]

        page.find('[data-testid="formatting-toolbar"] [data-testid="link"]').click
      end

      it 'prefills inline modal with the entire selection' do
        page.within '[data-testid="link-bubble-menu"]' do
          expect(page).to have_field('link-text', with: 'a b c')
          expect(page).to have_field('link-href', with: '')
        end
      end

      it 'expands the link and updates the link attributes if text is not updated' do
        page.within '[data-testid="link-bubble-menu"]' do
          fill_in 'link-href', with: 'https://about.gitlab.com'

          click_button 'Apply'
        end

        page.within content_editor_testid do
          expect(page).to have_selector('a[href="https://about.gitlab.com"]')
          expect(page.find('a')).to have_text('a b c')
          expect(page).to have_selector('strong', text: 'c')
        end
      end

      it 'expands the link, updates the link attributes and text if text is updated',
        quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/419684' do
        page.within '[data-testid="link-bubble-menu"]' do
          fill_in 'link-text', with: 'new text'
          fill_in 'link-href', with: 'https://about.gitlab.com'

          click_button 'Apply'
        end

        page.within content_editor_testid do
          expect(page).to have_selector('a[href="https://about.gitlab.com"]',
            text: 'new text'
          )
          expect(page).not_to have_selector('strong')
        end
      end
    end
  end
end
