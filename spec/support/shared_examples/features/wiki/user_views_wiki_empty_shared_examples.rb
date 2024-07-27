# frozen_string_literal: true

# Requires a context containing:
#   wiki

RSpec.shared_examples 'User views empty wiki' do
  let(:element) { page.find('.gl-empty-state[data-testid="wiki-empty-state"]') }
  let(:confluence_link) { 'Enable the Confluence Wiki integration' }

  shared_examples 'wiki is not found' do
    it 'shows an error message' do
      visit wiki_path(wiki)

      if @current_user
        expect(page).to have_content('Page not found')
      else
        expect(page).to have_content('You need to sign in')
      end
    end
  end

  shared_examples 'empty wiki message' do |writable: false, confluence: false|
    # This mirrors the logic in:
    # - app/views/shared/empty_states/_wikis.html.haml
    # - WikiHelper#wiki_empty_state_messages
    it 'shows the empty state message with the expected elements', :js do
      visit wiki_path(wiki)

      if writable
        expect(element).to have_content("Get started with wikis")
      else
        expect(element).to have_content("This wiki doesn't have any content yet")
      end

      if confluence
        expect(element).to have_link(confluence_link)
      else
        expect(element).not_to have_link(confluence_link)
      end

      if writable
        element.click_link 'Create your first page'

        expect(page).to have_button('Create page')
      else
        expect(element).not_to have_link('Create your first page')
      end
    end
  end
end
