# frozen_string_literal: true

# Requires a context containing:
#   wiki
#   user

RSpec.shared_examples 'User views wiki pages' do
  include WikiHelpers

  let!(:wiki_page1) do
    create(:wiki_page, wiki: wiki, title: '3 home', content: '3')
  end

  let!(:wiki_page2) do
    create(:wiki_page, wiki: wiki, title: '1 home', content: '1')
  end

  let!(:wiki_page3) do
    create(:wiki_page, wiki: wiki, title: '2 home', content: '2')
  end

  let(:pages) do
    page.find('.wiki-pages-list').all('li').map { |li| li.find('a') }
  end

  before do
    sign_in(user)
    visit(wiki_path(wiki, action: :pages))
  end

  context 'ordered by title' do
    let(:pages_ordered_by_title) { [wiki_page2, wiki_page3, wiki_page1] }

    context 'asc' do
      it 'pages are displayed in direct order' do
        pages.each.with_index do |page_title, index|
          expect(page_title.text).to eq(pages_ordered_by_title[index].title)
        end
      end
    end

    context 'desc' do
      before do
        page.within('.wiki-sort-dropdown') do
          page.find('.rspec-reverse-sort').click
        end
      end

      it 'pages are displayed in reversed order' do
        pages.reverse_each.with_index do |page_title, index|
          expect(page_title.text).to eq(pages_ordered_by_title[index].title)
        end
      end
    end
  end

  context 'when listing more pages than allowed items per page' do
    let(:items_per_page) { 1 }

    before do
      allow(Kaminari.config).to receive(:default_per_page).and_return(items_per_page)

      visit(wiki_path(wiki, action: :pages))
    end

    it 'shows pagination controls' do
      page.within('.gl-pagination') do
        expect(page).to have_text("Prev")
        expect(page).to have_link("1")
        expect(page).to have_link("2")
        expect(page).to have_link("3")
        expect(page).to have_link("Next")
      end
    end
  end

  it_behaves_like 'Wiki redirection'
end
