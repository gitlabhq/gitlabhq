# frozen_string_literal: true

# Requires a context containing:
#   wiki

RSpec.shared_examples 'User views empty wiki' do
  let(:element) { page.find('.row.empty-state') }
  let(:container_name) { wiki.container.class.name.humanize(capitalize: false) }
  let(:confluence_link) { 'Enable the Confluence Wiki integration' }

  shared_examples 'wiki is not found' do
    it 'shows an error message' do
      visit wiki_path(wiki)

      if @current_user
        expect(page).to have_content('Page Not Found')
      else
        expect(page).to have_content('You need to sign in')
      end
    end
  end

  shared_examples 'empty wiki message' do |writable: false, issuable: false, confluence: false, expect_button: true|
    # This mirrors the logic in:
    # - app/views/shared/empty_states/_wikis.html.haml
    # - WikiHelper#wiki_empty_state_messages
    it 'shows the empty state message with the expected elements', :js do
      visit wiki_path(wiki)

      if writable
        expect(element).to have_content("The wiki lets you write documentation for your #{container_name}")
      else
        expect(element).to have_content("This #{container_name} has no wiki pages")
        expect(element).to have_content("You must be a #{container_name} member")
      end

      if issuable && !writable
        expect(element).to have_content("improve the wiki for this #{container_name}")
        expect(element).to have_link("issue tracker", href: project_issues_path(project))
        expect(element.has_link?("Suggest wiki improvement", href: new_project_issue_path(project))).to be(expect_button)
      else
        expect(element).not_to have_content("improve the wiki for this #{container_name}")
        expect(element).not_to have_link("issue tracker")
        expect(element).not_to have_link("Suggest wiki improvement")
      end

      if confluence
        expect(element).to have_link(confluence_link)
      else
        expect(element).not_to have_link(confluence_link)
      end

      if writable
        element.click_link 'Create your first page'

        expect(page).to have_button('Create page', disabled: true)
      else
        expect(element).not_to have_link('Create your first page')
      end
    end
  end
end
