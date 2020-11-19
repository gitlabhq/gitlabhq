# frozen_string_literal: true

# Requires a context containing:
#   wiki
#   user

RSpec.shared_examples 'User deletes wiki page' do
  include WikiHelpers

  let(:wiki_page) { create(:wiki_page, wiki: wiki) }

  before do
    sign_in(user)
    visit wiki_page_path(wiki, wiki_page)
  end

  it 'deletes a page', :js do
    click_on('Edit')
    click_on('Delete')
    find('[data-testid="confirm_deletion_button"]').click

    expect(page).to have_content('Wiki page was successfully deleted.')
  end
end
