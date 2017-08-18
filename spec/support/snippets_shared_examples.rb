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
