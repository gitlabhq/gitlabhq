# frozen_string_literal: true

# Requires a context containing:
#   wiki

RSpec.shared_examples 'wiki file attachments' do
  include DropzoneHelper

  context 'uploading attachments', :js do
    def attach_with_dropzone(wait = false)
      dropzone_file([Rails.root.join('spec', 'fixtures', 'dk.png')], 0, wait)
    end

    context 'before uploading' do
      it 'shows "Attach a file or image" button' do
        expect(page).to have_selector('[data-testid="button-attach-file"]')
        expect(page).not_to have_selector('.uploading-progress-container', visible: true)
      end
    end

    context 'uploading is in progress', :capybara_ignore_server_errors do
      it 'cancels uploading on clicking to "Cancel" button' do
        slow_requests do
          attach_with_dropzone

          click_button 'Cancel'
        end

        expect(page).not_to have_button('Cancel')
        expect(page).not_to have_selector('.uploading-progress-container', visible: true)
      end

      it 'shows "Attaching a file" message on uploading 1 file' do
        slow_requests do
          attach_with_dropzone

          expect(page).to have_selector('.attaching-file-message', visible: true, text: 'Attaching a file -')
        end
      end
    end

    context 'uploading is complete' do
      it 'shows "Attach a file or image" button on uploading complete' do
        attach_with_dropzone
        wait_for_requests

        expect(page).to have_selector('[data-testid="button-attach-file"]')
        expect(page).not_to have_selector('.uploading-progress-container', visible: true)
      end

      it 'the markdown link is added to the page' do
        fill_in(:wiki_content, with: '')
        attach_with_dropzone(true)
        wait_for_requests

        expect(page.find('#wiki_content').value)
          .to match(%r{!\[dk\]\(uploads/\h{32}/dk\.png\)$})
      end

      it 'the links point to the wiki root url' do
        attach_with_dropzone(true)
        wait_for_requests

        click_button("Preview")
        file_path = page.find('input[name="files[]"]', visible: :hidden).value
        link = page.find('a.no-attachment-icon')['href']
        img_link = page.find('a.no-attachment-icon img')['src']

        expect(link).to eq img_link
        expect(URI.parse(link).path).to eq File.join(wiki.wiki_base_path, file_path)
      end

      it 'the file has been added to the wiki repository' do
        expect do
          attach_with_dropzone(true)
          wait_for_requests
        end.to change { wiki.repository.ls_files('HEAD').count }.by(1)

        file_path = page.find('input[name="files[]"]', visible: :hidden).value

        expect(wiki.find_file(file_path, 'HEAD').path).not_to be_nil
      end
    end
  end
end
