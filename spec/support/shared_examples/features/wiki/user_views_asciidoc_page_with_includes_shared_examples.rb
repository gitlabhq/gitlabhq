# frozen_string_literal: true

RSpec.shared_examples 'User views AsciiDoc page with includes' do
  let_it_be(:wiki_content_selector) { '[data-testid=wiki-page-content]' }
  let!(:included_wiki_page) { create_wiki_page('included_page', content: 'Content from the included page') }
  let!(:wiki_page) { create_wiki_page('home', content: "Content from the main page.\ninclude::included_page.asciidoc[]") }

  def create_wiki_page(title, content:)
    attrs = {
      title: title,
      content: content,
      format: :asciidoc
    }

    create(:wiki_page, wiki: wiki, **attrs)
  end

  before do
    sign_in(user)
  end

  context 'when the file being included exists', :js do
    it 'includes the file contents' do
      visit(wiki_page_path(wiki, wiki_page))

      page.within(:css, wiki_content_selector) do
        expect(page).to have_content('Content from the main page. Content from the included page')
      end
    end

    context 'when there are multiple versions of the wiki pages' do
      before do
        # rubocop:disable Rails/SaveBang
        included_wiki_page.update(message: 'updated included file', content: 'Updated content from the included page')
        wiki_page.update(message: 'updated wiki page', content: "Updated content from the main page.\ninclude::included_page.asciidoc[]")
        # rubocop:enable Rails/SaveBang
      end

      let(:latest_version_id) { wiki_page.versions.first.id }
      let(:oldest_version_id) { wiki_page.versions.last.id }

      context 'viewing the latest version' do
        it 'includes the latest content' do
          visit(wiki_page_path(wiki, wiki_page, version_id: latest_version_id))

          page.within(:css, wiki_content_selector) do
            expect(page).to have_content('Updated content from the main page. Updated content from the included page')
          end
        end
      end

      context 'viewing the original version' do
        it 'includes the content from the original version' do
          visit(wiki_page_path(wiki, wiki_page, version_id: oldest_version_id))

          page.within(:css, wiki_content_selector) do
            expect(page).to have_content('Content from the main page. Content from the included page')
          end
        end
      end
    end
  end

  context 'when the file being included does not exist', :js do
    before do
      included_wiki_page.delete
    end

    it 'outputs an error' do
      visit(wiki_page_path(wiki, wiki_page))

      page.within(:css, wiki_content_selector) do
        expect(page).to have_content('Content from the main page. [ERROR: include::included_page.asciidoc[] - unresolved directive]')
      end
    end
  end
end
