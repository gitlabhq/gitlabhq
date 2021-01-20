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
