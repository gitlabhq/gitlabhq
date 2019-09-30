# frozen_string_literal: true

shared_examples 'zoom quick actions' do
  let(:zoom_link) { 'https://zoom.us/j/123456789' }
  let(:invalid_zoom_link) { 'https://invalid-zoom' }

  before do
    issue.update!(description: description)
  end

  describe '/zoom' do
    shared_examples 'skip silently' do
      it 'skip addition silently' do
        add_note("/zoom #{zoom_link}")

        wait_for_requests

        expect(page).not_to have_content('Zoom meeting added')
        expect(page).not_to have_content('Failed to add a Zoom meeting')
        expect(issue.reload.description).to eq(description)
      end
    end

    shared_examples 'success' do
      it 'adds a Zoom link' do
        add_note("/zoom #{zoom_link}")

        wait_for_requests

        expect(page).to have_content('Zoom meeting added')
        expect(issue.reload.description).to end_with(zoom_link)
      end
    end

    context 'without issue description' do
      let(:description) { nil }

      include_examples 'success'

      it 'cannot add invalid zoom link' do
        add_note("/zoom #{invalid_zoom_link}")

        wait_for_requests

        expect(page).to have_content('Failed to add a Zoom meeting')
        expect(page).not_to have_content(zoom_link)
      end
    end

    context 'with Zoom link not at the end of the issue description' do
      let(:description) { "A link #{zoom_link} not at the end" }

      include_examples 'success'
    end

    context 'with Zoom link at end of the issue description' do
      let(:description) { "Text\n#{zoom_link}" }

      include_examples 'skip silently'
    end
  end

  describe '/remove_zoom' do
    shared_examples 'skip silently' do
      it 'skip removal silently' do
        add_note('/remove_zoom')

        wait_for_requests

        expect(page).not_to have_content('Zoom meeting removed')
        expect(page).not_to have_content('Failed to remove a Zoom meeting')
        expect(issue.reload.description).to eq(description)
      end
    end

    context 'with Zoom link in the description' do
      let(:description) { "Text with #{zoom_link}\n\n\n#{zoom_link}" }

      it 'removes last Zoom link' do
        add_note('/remove_zoom')

        wait_for_requests

        expect(page).to have_content('Zoom meeting removed')
        expect(issue.reload.description).to eq("Text with #{zoom_link}")
      end
    end

    context 'with a Zoom link not at the end of the description' do
      let(:description) { "A link #{zoom_link} not at the end" }

      include_examples 'skip silently'
    end
  end
end
