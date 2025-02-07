# frozen_string_literal: true

# Requires a context containing:
#   wiki
#   user

RSpec.shared_examples 'User updates wiki page' do
  include WikiHelpers

  let(:diagramsnet_url) { 'https://embed.diagrams.net' }

  before do
    sign_in(user)
    allow(Gitlab::CurrentSettings).to receive(:diagramsnet_enabled).and_return(true)
    allow(Gitlab::CurrentSettings).to receive(:diagramsnet_url).and_return(diagramsnet_url)
  end

  context 'when wiki is empty', :js do
    before do
      visit(wiki_path(wiki))

      click_link "Create your first page"
    end

    it 'redirects back to the home edit page' do
      page.within(:css, '[data-testid="wiki-form-actions"]') do
        click_on('Cancel')
      end

      expect(page).to have_current_path wiki_path(wiki), ignore_query: true
    end

    it 'updates a page that has a path', :js do
      fill_in(:wiki_title, with: 'one/two/three-test')

      page.within '.wiki-form' do
        fill_in(:wiki_content, with: 'wiki content')
        click_on('Create page')
      end

      expect(page).to have_current_path(%r{one/two/three-test}, ignore_query: true)
      expect(find('.wiki-pages')).to have_content('three')

      first(:link, text: 'three').click

      expect(find('[data-testid="page-heading"]')).to have_content('three')

      click_on('Edit')

      expect(page).to have_current_path(%r{one/two/three-test}, ignore_query: true)

      fill_in('Content', with: 'Updated Wiki Content')
      click_on('Save changes')

      expect(page).to have_content('Updated Wiki Content')
    end

    it_behaves_like 'wiki file attachments'
  end

  context 'when wiki is not empty', :js do
    let!(:wiki_page) { create(:wiki_page, wiki: wiki, title: 'home', content: 'Home page') }

    before do
      visit(wiki_path(wiki))

      click_on('Edit')
    end

    it 'updates a page', :js do
      # Commit message field should have correct value.
      expect(page).to have_field('wiki[message]', with: 'Update home')

      fill_in(:wiki_content, with: 'My awesome wiki!')
      click_button('Save changes')

      expect(page).to have_content('Home')
      expect(page).to have_content("Last edited by #{user.name}")
      expect(page).to have_content('My awesome wiki!')
    end

    it 'does not show comments when editing' do
      expect(page).not_to have_content('Comments')
    end

    it 'updates entry in redirects.yml file on changing page path' do
      wiki.repository.update_file(
        user, '.gitlab/redirects.yml',
        "home2: home\nfoo: bar",
        message: 'Add redirect', branch_name: 'master'
      )

      fill_in(:wiki_path, with: 'home2')
      fill_in(:wiki_content, with: 'My awesome wiki!')
      click_button('Save changes')

      expect(page).to have_content('Home')
      expect(page).to have_content('My awesome wiki!')

      expect(wiki.repository.blob_at('master', '.gitlab/redirects.yml').data).to eq("---\nfoo: bar\nhome: home2\n")
    end

    it 'saves page content in local storage if the user navigates away', :js do
      fill_in(:wiki_title, with: "Test title")
      fill_in(:wiki_content, with: "This is a test")
      fill_in(:wiki_message, with: "Test commit message")

      refresh

      expect(page).to have_field(:wiki_title, with: "Test title")
      expect(page).to have_field(:wiki_content, with: "This is a test")
      expect(page).to have_field(:wiki_message, with: "Test commit message")
    end

    it 'updates the commit message as the title is changed', :js do
      fill_in(:wiki_title, with: '& < > \ \ { } &')

      expect(page).to have_field('wiki[message]', with: 'Update & < > \ \ { } &')
    end

    it 'correctly escapes the commit message entities', :js do
      fill_in(:wiki_title, with: 'Wiki title')

      expect(page).to have_field('wiki[message]', with: 'Update Wiki title')
    end

    it "does not disable the submit button", :js do
      page.within(".wiki-form") do
        fill_in(:wiki_content, with: "")
        expect(page).to have_button('Save changes', disabled: false)
      end
    end

    it 'shows the emoji autocompletion dropdown', :js do
      find('#wiki_content').native.send_keys('')
      fill_in(:wiki_content, with: ':')

      expect(page).to have_selector('.atwho-view')
    end

    it 'updates a page', :js do
      fill_in('Content', with: 'Updated Wiki Content')
      click_on('Save changes')

      expect(page).to have_content('Updated Wiki Content')
    end

    it 'cancels editing of a page' do
      page.within(:css, '[data-testid="wiki-form-actions"]') do
        click_on('Cancel')
      end

      expect(page).to have_current_path(wiki_page_path(wiki, wiki_page), ignore_query: true)
    end

    it_behaves_like 'wiki file attachments'

    context 'when multiple people edit the page at the same time' do
      it 'preserves user changes in the wiki editor', :js do
        wiki_page.update(content: 'Some Other Updates') # rubocop:disable Rails/SaveBang

        fill_in('Content', with: 'Updated Wiki Content')
        click_on('Save changes')

        expect(page).to have_content('Someone edited the page the same time you did.')
        expect(find('textarea#wiki_content').value).to eq('Updated Wiki Content')
      end
    end

    it_behaves_like 'rich text editor - common'
    it_behaves_like 'rich text editor - autocomplete', {
      with_expanded_references: false,
      with_quick_actions: false
    }
    it_behaves_like 'rich text editor - diagrams'
  end

  context 'when the page is in a subdir', :js do
    let(:page_name) { 'page_name' }
    let(:page_dir) { "foo/bar/#{page_name}" }
    let!(:wiki_page) { create(:wiki_page, wiki: wiki, title: page_dir, content: 'Home page') }

    before do
      visit wiki_page_path(wiki, wiki_page, action: :edit)
    end

    it 'does not move the page to root folder on changing the title' do
      fill_in(:wiki_title, with: "/#{page_name}")

      click_button('Save changes')

      expect(page).to have_current_path(wiki_page_path(wiki, page_dir), ignore_query: true)
    end

    it 'moves the page to the root folder on changing the path', :js do
      fill_in(:wiki_path, with: "/#{page_name}")

      click_button('Save changes')

      expect(page).to have_current_path(wiki_page_path(wiki, page_name), ignore_query: true)
    end

    it 'moves the page to other dir on changing the path', :js do
      new_page_dir = "foo1/bar1/#{page_name}"

      fill_in(:wiki_path, with: new_page_dir)

      click_button('Save changes')

      expect(page).to have_current_path(wiki_page_path(wiki, new_page_dir), ignore_query: true)
    end

    it 'does not move the page to other dir on changing the title' do
      new_page_dir = "foo1/bar1/#{page_name}"

      fill_in(:wiki_title, with: new_page_dir)

      click_button('Save changes')

      expect(page).to have_current_path(wiki_page_path(wiki, page_dir), ignore_query: true)
    end

    it 'remains in the same place if path has not changed', :js do
      original_path = wiki_page_path(wiki, wiki_page)

      fill_in(:wiki_path, with: page_name)

      click_button('Save changes')

      expect(page).to have_current_path(original_path, ignore_query: true)
    end

    it 'can be moved to a different dir with a different name by changing the path', :js do
      new_page_dir = "foo1/bar1/new_page_name"

      fill_in(:wiki_path, with: new_page_dir)

      click_button('Save changes')

      expect(page).to have_current_path(wiki_page_path(wiki, new_page_dir), ignore_query: true)
    end

    it 'can be renamed and moved to the root folder by changing the path', :js do
      new_name = 'new_page_name'

      fill_in(:wiki_path, with: "/#{new_name}")

      click_button('Save changes')

      expect(page).to have_current_path(wiki_page_path(wiki, new_name), ignore_query: true)
    end

    it 'squishes the path before creating the page', :js do
      new_page_dir = "  foo1 /  bar1  /  #{page_name}  "

      fill_in(:wiki_path, with: new_page_dir)

      click_button('Save changes')

      expect(page).to have_current_path(wiki_page_path(wiki, "foo1/bar1/#{page_name}"), ignore_query: true)
    end

    it_behaves_like 'wiki file attachments'
  end

  context 'when an existing page exceeds the content size limit' do
    let!(:wiki_page) { create(:wiki_page, wiki: wiki, content: "one\ntwo\nthree") }

    before do
      stub_application_setting(wiki_page_max_content_bytes: 10)

      visit wiki_page_path(wiki_page.wiki, wiki_page, action: :edit)
    end

    it 'allows changing the path if the content does not change', :js do
      fill_in :wiki_path, with: 'new-path'
      click_on 'Save changes'

      expect(page).to have_content('Wiki page was successfully updated.')
    end

    it 'shows a validation error when trying to change the content', :js do
      fill_in 'Content', with: 'new content'
      click_on 'Save changes'

      expect(page).to have_content('The form contains the following error:')
      expect(page).to have_content('Content is too long (11 B). The maximum size is 10 B.')
    end
  end
end
