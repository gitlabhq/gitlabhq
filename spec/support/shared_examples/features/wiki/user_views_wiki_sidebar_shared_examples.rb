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

    it 'renders a default sidebar when there is no customized sidebar' do
      visit wiki_path(wiki)

      expect(page).to have_content('another')
      expect(page).not_to have_link('View All Pages')
    end

    context 'when there is a customized sidebar' do
      before do
        create(:wiki_page, wiki: wiki, title: '_sidebar', content: 'My customized sidebar')
      end

      it 'renders my customized sidebar instead of the default one' do
        visit wiki_path(wiki)

        expect(page).to have_content('My customized sidebar')
        expect(page).not_to have_content('Another')
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
