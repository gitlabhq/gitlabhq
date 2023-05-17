# frozen_string_literal: true

# Requires a context containing:
#   wiki
#   user

RSpec.shared_examples 'User views wiki sidebar' do
  include WikiHelpers

  before do
    sign_in(user)
  end

  context 'when there are some existing pages' do
    before do
      create(:wiki_page, wiki: wiki, title: 'home', content: 'home')
      create(:wiki_page, wiki: wiki, title: 'another', content: 'another')
    end

    context 'when there is no custom sidebar' do
      before do
        visit wiki_path(wiki)
      end

      it 'renders a default sidebar' do
        within('.right-sidebar') do
          expect(page).to have_content('another')
          expect(page).not_to have_link('View All Pages')
        end
      end

      it 'can create a custom sidebar', :js do
        click_on 'Edit sidebar'
        fill_in :wiki_content, with: 'My custom sidebar'
        click_on 'Create page'

        within('.right-sidebar') do
          expect(page).to have_content('My custom sidebar')
          expect(page).not_to have_content('another')
        end
      end
    end

    context 'when there is a custom sidebar' do
      before do
        create(:wiki_page, wiki: wiki, title: '_sidebar', content: 'My custom sidebar')

        visit wiki_path(wiki)
      end

      it 'renders the custom sidebar instead of the default one' do
        within('.right-sidebar') do
          expect(page).to have_content('My custom sidebar')
          expect(page).not_to have_content('another')
        end
      end

      it 'can edit the custom sidebar', :js do
        click_on 'Edit sidebar'

        expect(page).to have_field(:wiki_content, with: 'My custom sidebar')

        fill_in :wiki_content, with: 'My other custom sidebar'
        click_on 'Save changes'

        within('.right-sidebar') do
          expect(page).to have_content('My other custom sidebar')
        end
      end
    end
  end

  context 'when there are 15 existing pages' do
    before do
      (1..5).each { |i| create(:wiki_page, wiki: wiki, title: "my page #{i}") }
      (6..10).each { |i| create(:wiki_page, wiki: wiki, title: "parent/my page #{i}") }
      (11..15).each { |i| create(:wiki_page, wiki: wiki, title: "grandparent/parent/my page #{i}") }
    end

    it 'shows all pages in the sidebar' do
      visit wiki_path(wiki)

      (1..15).each { |i| expect(page).to have_content("my page #{i}") }
      expect(page).not_to have_link('View All Pages')
    end

    it 'shows all collapse buttons in the sidebar' do
      visit wiki_path(wiki)

      within('.right-sidebar') do
        expect(page.all("[data-testid='chevron-down-icon']").size).to eq(3)
      end
    end

    it 'collapses/expands children when click collapse/expand button in the sidebar', :js do
      visit wiki_path(wiki)

      within('.right-sidebar') do
        first("[data-testid='chevron-down-icon']").click
        (11..15).each { |i| expect(page).not_to have_content("my page #{i}") }
        expect(page.all("[data-testid='chevron-down-icon']").size).to eq(1)
        expect(page.all("[data-testid='chevron-right-icon']").size).to eq(1)

        first("[data-testid='chevron-right-icon']").click
        (11..15).each { |i| expect(page).to have_content("my page #{i}") }
        expect(page.all("[data-testid='chevron-down-icon']").size).to eq(3)
        expect(page.all("[data-testid='chevron-right-icon']").size).to eq(0)
      end
    end

    it 'shows create child page button when hover to the page title in the sidebar', :js do
      visit wiki_path(wiki)

      within('.right-sidebar') do
        first_wiki_list = first("[data-testid='wiki-list']")
        wiki_link = first("[data-testid='wiki-list'] a:last-of-type")['href']

        first_wiki_list.hover
        wiki_new_page_link = first("[data-testid='wiki-list'] a")['href']

        expect(wiki_new_page_link).to eq "#{wiki_link}/%7Bnew_page_title%7D"
      end
    end

    context 'when there are more than 15 existing pages' do
      before do
        create(:wiki_page, wiki: wiki, title: 'my page 16')
      end

      it 'shows the first 15 pages in the sidebar' do
        visit wiki_path(wiki)

        expect(page).to have_text('my page', count: 15)
        expect(page).to have_link('View All Pages')
      end
    end
  end
end
