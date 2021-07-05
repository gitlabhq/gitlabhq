# frozen_string_literal: true

# Requires a context containing:
#   wiki
#   user

RSpec.shared_examples 'User deletes wiki page' do
  include WikiHelpers

  let_it_be(:developer) { create(:user) }

  let(:wiki_page) { create(:wiki_page, wiki: wiki) }

  before do
    wiki.container.add_developer(developer)

    sign_in(user)
    visit wiki_page_path(wiki, wiki_page)
  end

  shared_examples 'deletes a wiki page' do
    specify 'deletes a page', :js do
      click_on('Edit')
      click_on('Delete')
      find('[data-testid="confirm_deletion_button"]').click

      expect(page).to have_content('Wiki page was successfully deleted.')
    end
  end

  context 'when user is the owner or maintainer' do
    it_behaves_like 'deletes a wiki page'
  end

  context 'when user is a developer' do
    let(:user) { developer }

    it_behaves_like 'deletes a wiki page'
  end
end
