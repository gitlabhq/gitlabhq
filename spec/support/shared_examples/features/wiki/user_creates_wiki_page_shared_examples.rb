# frozen_string_literal: true

# Requires a context containing:
#   wiki
#   user

RSpec.shared_examples 'User creates wiki page' do
  include WikiHelpers

  before do
    sign_in(user)
  end

  context "when wiki is empty" do
    before do
      visit wiki_path(wiki)

      click_link "Create your first page"
    end

    it 'shows all available formats in the dropdown' do
      Wiki::VALID_USER_MARKUPS.each do |key, markup|
        expect(page).to have_css("#wiki_format option[value=#{key}]", text: markup[:name])
      end
    end

    it "does not disable the submit button", :js do
      page.within(".wiki-form") do
        fill_in(:wiki_content, with: "")
        expect(page).to have_button('Create page', disabled: false)
      end
    end

    it "makes sure links to unknown pages work correctly", :js do
      page.within(".wiki-form") do
        fill_in(:wiki_content, with: "[link test](test)")

        click_on("Create page")
      end

      expect(page).to have_content("Home").and have_content("link test")

      click_link("link test")

      expect(page).to have_content("New page")
    end

    it "shows non-escaped link in the pages list", :js do
      fill_in(:wiki_title, with: "one/two/three-test")

      page.within(".wiki-form") do
        fill_in(:wiki_content, with: "wiki content")

        click_on("Create page")
      end

      expect(page).to have_current_path(%r{one/two/three-test}, ignore_query: true)
      expect(page).to have_link(href: wiki_page_path(wiki, 'one/two/three-test'))
    end

    it "has `Create home` as a commit message", :js do
      wait_for_requests

      expect(page).to have_field("wiki[message]", with: "Create home")
    end

    it "creates a page from the home page", :js do
      fill_in(:wiki_content, with: "[test](test)\n[GitLab API doc](api)\n[Rake tasks](raketasks)\n# Wiki header\n")
      fill_in(:wiki_message, with: "Adding links to wiki")

      page.within(".wiki-form") do
        click_button("Create page")
      end

      expect(page).to have_current_path(wiki_page_path(wiki, "home"), ignore_query: true)
      expect(page).to have_content("test GitLab API doc Rake tasks Wiki header")
                  .and have_content("Home")
                  .and have_content("Last edited by #{user.name}")
                  .and have_header_with_correct_id_and_link(1, "Wiki header", "wiki-header")

      click_link("test")

      expect(page).to have_current_path(wiki_page_path(wiki, "test"), ignore_query: true)

      page.within(:css, ".wiki-page-header") do
        expect(page).to have_content("New page")
      end

      click_link("Home")

      expect(page).to have_current_path(wiki_page_path(wiki, "home"), ignore_query: true)

      click_link("GitLab API")

      expect(page).to have_current_path(wiki_page_path(wiki, "api"), ignore_query: true)

      page.within(:css, ".wiki-page-header") do
        expect(page).to have_content("New page")
      end

      click_link("Home")

      expect(page).to have_current_path(wiki_page_path(wiki, "home"), ignore_query: true)

      click_link("Rake tasks")

      expect(page).to have_current_path(wiki_page_path(wiki, "raketasks"), ignore_query: true)

      page.within(:css, ".wiki-page-header") do
        expect(page).to have_content("New page")
      end
    end

    it "creates ASCII wiki with LaTeX blocks", :js do
      stub_application_setting(plantuml_url: "http://localhost", plantuml_enabled: true)

      ascii_content = <<~MD
        :stem: latexmath

        [stem]
        ++++
        \\sqrt{4} = 2
        ++++

        another part

        [latexmath]
        ++++
        \\beta_x \\gamma
        ++++

        stem:[2+2] is 4
      MD

      find("#wiki_format option[value=asciidoc]").select_option

      fill_in(:wiki_content, with: ascii_content)

      page.within(".wiki-form") do
        click_button("Create page")
      end

      page.within ".js-wiki-page-content" do
        expect(page).to have_selector(".katex", count: 3).and have_content("2+2 is 4")
      end
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

    it 'creates a wiki page with Org markup', :aggregate_failures, :js do
      org_content = <<~ORG
        * Heading
        ** Subheading
        [[home][Link to Home]]
      ORG

      page.within('.wiki-form') do
        find('#wiki_format option[value=org]').select_option
        fill_in(:wiki_content, with: org_content)
        click_button('Create page')
      end

      expect(page).to have_selector('h1', text: 'Heading')
      expect(page).to have_selector('h2', text: 'Subheading')
      expect(page).to have_link(href: wiki_page_path(wiki, 'home'))
    end

    it_behaves_like 'wiki file attachments'
    it_behaves_like 'autocompletes items'
  end

  context "when wiki is not empty", :js do
    before do
      create(:wiki_page, wiki: wiki, title: 'home', content: 'Home page')

      visit wiki_path(wiki)
    end

    context "via the `new wiki page` page", :js do
      it "creates a page with a single word" do
        find_by_testid('wiki-more-dropdown').click
        click_link("New page")

        page.within(".wiki-form") do
          fill_in(:wiki_title, with: "foo")
          fill_in(:wiki_content, with: "My awesome wiki!")
        end

        # Commit message field should have correct value.
        expect(page).to have_field("wiki[message]", with: "Create foo")

        click_button("Create page")

        expect(page).to have_content("foo")
                    .and have_content("Last edited by #{user.name}")
                    .and have_content("My awesome wiki!")
      end

      it "creates a page with spaces in the name", :js do
        find_by_testid('wiki-more-dropdown').click
        click_link("New page")

        page.within(".wiki-form") do
          fill_in(:wiki_title, with: "Spaces in the name")
          fill_in(:wiki_content, with: "My awesome wiki!")
        end

        # Commit message field should have correct value.
        expect(page).to have_field("wiki[message]", with: "Create Spaces in the name")

        click_button("Create page")

        expect(page).to have_content("Spaces in the name")
                    .and have_content("Last edited by #{user.name}")
                    .and have_content("My awesome wiki!")
      end

      it "creates a page with hyphens in the name", :js do
        find_by_testid('wiki-more-dropdown').click
        click_link("New page")

        page.within(".wiki-form") do
          fill_in(:wiki_title, with: "hyphens-in-the-name")
          fill_in(:wiki_content, with: "My awesome wiki!")
        end

        # Commit message field should have correct value.
        expect(page).to have_field("wiki[message]", with: "Create hyphens in the name")

        page.within(".wiki-form") do
          fill_in(:wiki_content, with: "My awesome wiki!")

          click_button("Create page")
        end

        expect(page).to have_content("hyphens in the name")
                    .and have_content("Last edited by #{user.name}")
                    .and have_content("My awesome wiki!")
      end

      it 'removes entry from redirects.yml file' do
        wiki.repository.update_file(
          user, '.gitlab/redirects.yml',
          "foo: bar\nbaz: doe",
          message: 'Add redirect', branch_name: 'master'
        )

        find_by_testid('wiki-more-dropdown').click
        click_link('New page')

        page.within('.wiki-form') do
          fill_in(:wiki_title, with: 'foo')
          fill_in(:wiki_content, with: 'testing redirects')
          click_button('Create page')
        end

        expect(page).to have_content('foo')

        expect(wiki.repository.blob_at('master', '.gitlab/redirects.yml').data).to eq("---\nbaz: doe\n")
      end

      context 'when a server side validation error is returned' do
        it "still displays edit form", :js do
          find_by_testid('wiki-more-dropdown').click
          click_link("New page")

          page.within(".wiki-form") do
            fill_in(:wiki_title, with: "home")
            fill_in(:wiki_content, with: "My awesome home page!")
          end

          # Submits page with a name already in use to trigger a validation error
          click_button("Create page")

          expect(page).to have_field(:wiki_title)
          expect(page).to have_field(:wiki_content)
        end
      end
    end

    it "shows the emoji autocompletion dropdown", :js do
      find_by_testid('wiki-more-dropdown').click
      click_link("New page")

      page.within(".wiki-form") do
        find("#wiki_content").native.send_keys("")

        fill_in(:wiki_content, with: ":")
      end

      expect(page).to have_selector(".atwho-view")
    end

    it_behaves_like 'user applies wiki templates'
  end
end
