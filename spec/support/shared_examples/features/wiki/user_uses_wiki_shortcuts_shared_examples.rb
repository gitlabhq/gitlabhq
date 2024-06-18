# frozen_string_literal: true

# Requires a context containing:
#   wiki
#   user

RSpec.shared_examples 'User uses wiki shortcuts' do
  let(:wiki_page) { create(:wiki_page, wiki: wiki, title: 'home', content: 'Home page') }

  before do
    sign_in(user)
    visit wiki_page_path(wiki, wiki_page)
  end

  it 'visit edit wiki page using "e" keyboard shortcut', :js do
    find('body').native.send_key('e')

    expect(find('#wiki_title').value).to eq('home')
  end
end
