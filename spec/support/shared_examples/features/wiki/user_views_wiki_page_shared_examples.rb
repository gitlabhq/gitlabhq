# frozen_string_literal: true

# Requires a context containing:
#   wiki
#   user

RSpec.shared_examples 'User views a wiki page' do
  include WikiHelpers

  let(:path) { 'image.png' }
  let(:wiki_page) do
    create(
      :wiki_page,
      wiki: wiki,
      title: 'home', content: "Look at this [image](#{path})\n\n ![alt text](#{path})"
    )
  end

  let(:more_actions_dropdown) do
    find('[data-testid="wiki-more-dropdown"] button')
  end

  before do
    sign_in(user)
  end

  context 'when wiki is empty', :js do
    before do
      visit wiki_path(wiki)

      click_link "Create your first page"

      fill_in(:wiki_title, with: 'one/two/three-test')

      page.within('.wiki-form') do
        fill_in(:wiki_content, with: 'wiki content')
        click_on('Create page')
      end

      expect(page).to have_content('Wiki page was successfully created.')
    end

    it 'shows the history of a page that has a path', :js do
      expect(page).to have_current_path(%r{one/two/three-test})

      first(:link, text: 'three').click

      more_actions_dropdown.click
      click_on('Page history')

      expect(page).to have_current_path(%r{one/two/three-test})

      page.within(:css, '.wiki-page-header') do
        expect(page).to have_content('History')
      end
    end

    it 'shows an old version of a page', :js do
      expect(page).to have_current_path(%r{one/two/three-test})
      expect(find('.wiki-pages')).to have_content('three')

      first(:link, text: 'three').click

      expect(find('[data-testid="page-heading"]')).to have_content('three')

      click_on('Edit')

      expect(page).to have_current_path(%r{one/two/three-test})
      expect(page).to have_css('#wiki_title')

      fill_in('Content', with: 'Updated Wiki Content')
      click_on('Save changes')

      expect(page).to have_content('Wiki page was successfully updated.')

      more_actions_dropdown.click
      click_on('Page history')

      within('.wiki-page-header') do
        expect(page).to have_content('History')
      end

      within('.wiki-history') do
        expect(page).to have_css('a[href*="?version_id"]', count: 4)
      end
    end
  end

  context 'when a page does not have history' do
    before do
      visit(wiki_page_path(wiki, wiki_page))
    end

    it 'shows all the pages' do
      expect(page).to have_content(user.name)
      expect(find('.wiki-pages')).to have_content(wiki_page.title.capitalize)
    end

    context 'shows a file stored in a page' do
      let(:path) { upload_file_to_wiki(wiki, user, 'dk.png') }

      it do
        expect(page).to have_xpath("//img[@src='#{wiki.wiki_base_path}/#{path}']")
        expect(page).to have_link('image', href: "#{wiki.wiki_base_path}/#{path}")

        click_on('image')

        expect(page).to have_current_path(%r{wikis/#{path}})
      end
    end

    it 'shows the creation page if file does not exist' do
      expect(page).to have_link('image', href: "#{wiki.wiki_base_path}/#{path}")

      click_on('image')

      expect(page).to have_current_path(%r{wikis/#{path}})
      expect(page).to have_content('New page')
    end
  end

  context 'when a page has history' do
    before do
      wiki_page.update(message: 'updated home', content: 'updated [some link](other-page)') # rubocop:disable Rails/SaveBang
    end

    it 'shows the page history', :js do
      visit(wiki_page_path(wiki, wiki_page))

      expect(page).to have_selector('[data-testid="wiki-edit-button"]')

      more_actions_dropdown.click
      click_on('Page history')

      expect(page).to have_content(user.name)
      expect(page).to have_content("#{user.username} created page: home")
      expect(page).to have_content('updated home')
    end

    it 'does not show the "Edit" button' do
      visit(wiki_page_path(wiki, wiki_page, version_id: wiki_page.versions.last.id))

      expect(page).not_to have_selector('[data-testid="wiki-edit-button"]')
    end

    context 'show the diff' do
      def expect_diff_links(commit)
        diff_path = wiki_page_path(wiki, wiki_page, version_id: commit, action: :diff)

        expect(page).to have_link('Hide whitespace changes', href: "#{diff_path}&w=1")
        expect(page).to have_link('Inline', href: "#{diff_path}&view=inline")
        expect(page).to have_link('Side-by-side', href: "#{diff_path}&view=parallel")
        expect(page).to have_link("View page @ #{commit.short_id}", href: wiki_page_path(wiki, wiki_page, version_id: commit))
        expect(page).to have_css('.diff-file[data-blob-diff-path="%s"]' % diff_path)
      end

      it 'links to the correct diffs' do
        visit wiki_page_path(wiki, wiki_page, action: :history)

        commit1 = wiki.commit('HEAD^')
        commit2 = wiki.commit

        expect(page).to have_link('created page: home', href: wiki_page_path(wiki, wiki_page, version_id: commit1, action: :diff))
        expect(page).to have_link('updated home', href: wiki_page_path(wiki, wiki_page, version_id: commit2, action: :diff))
      end

      it 'between the current and the previous version of a page', :js do
        commit = wiki.commit
        visit wiki_page_path(wiki, wiki_page, version_id: commit, action: :diff)

        expect(page).to have_content('by Sidney Jones')
        expect(page).to have_content('updated home')
        expect(page).to have_content('Showing 1 changed file with 1 addition and 3 deletions')
        expect(page).to have_content('some link')

        expect_diff_links(commit)
      end

      it 'between two old versions of a page', :js do
        wiki_page.update(message: 'latest home change', content: 'updated [another link](other-page)') # rubocop:disable Rails/SaveBang:
        commit = wiki.commit('HEAD^')
        visit wiki_page_path(wiki, wiki_page, version_id: commit, action: :diff)

        expect(page).to have_content('by Sidney Jones')
        expect(page).to have_content('updated home')
        expect(page).to have_content('Showing 1 changed file with 1 addition and 3 deletions')
        expect(page).to have_content('some link')
        expect(page).not_to have_content('latest home change')
        expect(page).not_to have_content('another link')

        expect_diff_links(commit)
      end

      it 'for the oldest version of a page', :js do
        commit = wiki.commit('HEAD^')
        visit wiki_page_path(wiki, wiki_page, version_id: commit, action: :diff)

        expect(page).to have_content('by Sidney Jones')
        expect(page).to have_content('created page: home')
        expect(page).to have_content('Showing 1 changed file with 4 additions and 0 deletions')
        expect(page).to have_content('Look at this')

        expect_diff_links(commit)
      end
    end
  end

  context 'when a page has special characters in its title' do
    let(:title) { '<foo> !@#$%^&*()[]{}=_+\'"\\|<>? <bar>' }

    before do
      wiki_page.update(title: title) # rubocop:disable Rails/SaveBang
    end

    it 'preserves the special characters' do
      visit(wiki_page_path(wiki, wiki_page))

      expect(page).to have_css('[data-testid="page-heading"]', text: title)
      expect(page).to have_css('.wiki-pages li', text: title)
    end
  end

  context 'when a page has XSS in its title or content' do
    let(:title) { '<script>alert("title")<script>' }

    before do
      wiki_page.update(title: title, content: 'foo <script>alert("content")</script> bar') # rubocop:disable Rails/SaveBang
    end

    it 'safely displays the page' do
      visit(wiki_page_path(wiki, wiki_page))

      expect(page).to have_selector('[data-testid="page-heading"]', text: title)
      expect(page).to have_content('foo bar')
    end
  end

  context 'when a page has XSS in its message' do
    before do
      wiki_page.update(message: '<script>alert(true)<script>', content: 'XSS update') # rubocop:disable Rails/SaveBang
    end

    it 'safely displays the message' do
      visit(wiki_page_path(wiki, wiki_page, action: :history))

      expect(page).to have_content('<script>alert(true)<script>')
    end
  end

  context 'when a page has headings' do
    before do
      wiki_page.update(content: "# Heading 1\n\n## Heading 1.1\n\n### Heading 1.1.1\n\n# Heading 2") # rubocop:disable Rails/SaveBang -- not an ActiveRecord
    end

    it 'displays the table of contents for the page' do
      visit(wiki_page_path(wiki, wiki_page))

      within '.js-wiki-toc' do
        expect(page).to have_content('On this page')

        expect(page).to have_content('Heading 1')
        expect(page).to have_content('Heading 1.1')
        expect(page).to have_content('Heading 1.1.1')
        expect(page).to have_content('Heading 2')
      end
    end
  end

  context 'when page has invalid content encoding' do
    let(:content) { (+'whatever').force_encoding('ISO-8859-1') }

    before do
      allow(Gitlab::EncodingHelper).to receive(:encode!).and_return(content)

      visit(wiki_page_path(wiki, wiki_page))
    end

    it 'does not show "Edit" button' do
      expect(page).not_to have_selector('[data-testid="wiki-edit-button"]')
    end

    it 'shows error' do
      page.within(:css, '.flash-notice') do
        expect(page).to have_content('The content of this page is not encoded in UTF-8. Edits can only be made via the Git repository.')
      end
    end
  end

  it 'opens a default wiki page', :js do
    visit wiki.container.web_url

    within_testid('super-sidebar') do
      click_button 'Plan'
      click_link 'Wiki'
    end

    click_link "Create your first page"

    expect(page).to have_content('New page')
  end
end
