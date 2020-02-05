# frozen_string_literal: true

# These shared examples expect a `snippets` array of snippets
RSpec.shared_examples 'paginated snippets' do |remote: false|
  it "is limited to #{Snippet.default_per_page} items per page" do
    expect(page.all('.snippets-list-holder .snippet-row').count).to eq(Snippet.default_per_page)
  end

  context 'clicking on the link to the second page' do
    before do
      click_link('2')
      wait_for_requests if remote
    end

    it 'shows the remaining snippets' do
      remaining_snippets_count = [snippets.size - Snippet.default_per_page, Snippet.default_per_page].min
      expect(page).to have_selector('.snippets-list-holder .snippet-row', count: remaining_snippets_count)
    end
  end
end

RSpec.shared_examples 'tabs with counts' do
  let(:tabs) { page.all('.snippet-scope-menu li') }

  it 'shows a tab for All snippets and count' do
    tab = tabs[0]

    expect(tab.text).to include('All')
    expect(tab.find('.badge').text).to eq(counts[:all])
  end

  it 'shows a tab for Private snippets and count' do
    tab = tabs[1]

    expect(tab.text).to include('Private')
    expect(tab.find('.badge').text).to eq(counts[:private])
  end

  it 'shows a tab for Internal snippets and count' do
    tab = tabs[2]

    expect(tab.text).to include('Internal')
    expect(tab.find('.badge').text).to eq(counts[:internal])
  end

  it 'shows a tab for Public snippets and count' do
    tab = tabs[3]

    expect(tab.text).to include('Public')
    expect(tab.find('.badge').text).to eq(counts[:public])
  end
end
