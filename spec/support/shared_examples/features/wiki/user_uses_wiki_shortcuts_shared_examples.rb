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

  # rubocop:disable Layout/LineLength -- short lived quarantine link
  it 'visit edit wiki page using "e" keyboard shortcut', :js, quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/572733' do
    find('body').native.send_key('e')

    expect(find('#wiki_title').value).to eq('home')
  end
  # rubocop:enable Layout/LineLength
end
