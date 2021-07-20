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
    before do |example|
      visit wiki_path(wiki)

      wait_for_svg_to_be_loaded(example)

      click_link "Create your first page"
    end

    it "disables the submit button", :js do
      page.within(".wiki-form") do
        fill_in(:wiki_content, with: "")
        expect(page).to have_button('Create page', disabled: true)
      end
    end

    it "makes sure links to unknown pages work correctly", :js do
      page.within(".wiki-form") do
        fill_in(:wiki_content, with: "[link test](test)")

        click_on("Create page")
      end

      expect(page).to have_content("Home").and have_content("link test")

      click_link("link test")

      expect(page).to have_content("Create New Page")
    end

    it "shows non-escaped link in the pages list", :js do
      fill_in(:wiki_title, with: "one/two/three-test")

      page.within(".wiki-form") do
        fill_in(:wiki_content, with: "wiki content")

        click_on("Create page")
      end

      expect(current_path).to include("one/two/three-test")
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

      expect(current_path).to eq(wiki_page_path(wiki, "home"))
      expect(page).to have_content("test GitLab API doc Rake tasks Wiki header")
                  .and have_content("Home")
                  .and have_content("Last edited by #{user.name}")
                  .and have_header_with_correct_id_and_link(1, "Wiki header", "wiki-header")

      click_link("test")

      expect(current_path).to eq(wiki_page_path(wiki, "test"))

      page.within(:css, ".wiki-page-header") do
        expect(page).to have_content("Create New Page")
      end

      click_link("Home")

      expect(current_path).to eq(wiki_page_path(wiki, "home"))

      click_link("GitLab API")

      expect(current_path).to eq(wiki_page_path(wiki, "api"))

      page.within(:css, ".wiki-page-header") do
        expect(page).to have_content("Create")
      end

      click_link("Home")

      expect(current_path).to eq(wiki_page_path(wiki, "home"))

      click_link("Rake tasks")

      expect(current_path).to eq(wiki_page_path(wiki, "raketasks"))

      page.within(:css, ".wiki-page-header") do
        expect(page).to have_content("Create")
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

      page.within ".md" do
        expect(page).to have_selector(".katex", count: 3).and have_content("2+2 is 4")
      end
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
  end

  context "when wiki is not empty", :js do
    before do
      create(:wiki_page, wiki: wiki, title: 'home', content: 'Home page')

      visit wiki_path(wiki)
    end

    context "via the `new wiki page` page", :js do
      it "creates a page with a single word" do
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
    end

    it "shows the emoji autocompletion dropdown", :js do
      click_link("New page")

      page.within(".wiki-form") do
        find("#wiki_content").native.send_keys("")

        fill_in(:wiki_content, with: ":")
      end

      expect(page).to have_selector(".atwho-view")
    end
  end
end
