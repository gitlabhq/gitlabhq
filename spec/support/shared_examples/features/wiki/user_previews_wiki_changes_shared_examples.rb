# frozen_string_literal: true

# Requires a context containing:
#   wiki
#   user

RSpec.shared_examples 'User previews wiki changes' do
  let(:wiki_page) { build(:wiki_page, wiki: wiki) }

  before do
    sign_in(user)
  end

  shared_examples 'relative links' do
    let_it_be(:page_content) do
      <<~HEREDOC
        Some text so key event for [ does not trigger an incorrect replacement.
        [regular link](regular)
        [relative link 1](../relative)
        [relative link 2](./relative)
        [relative link 3](./e/f/relative)
        [spaced link](title with spaces)
      HEREDOC
    end

    def relative_path(path)
      (Pathname.new(wiki.wiki_base_path) + File.dirname(wiki_page.path).tr(' ', '-') + path).to_s
    end

    shared_examples "rewrites relative links" do
      specify do
        expect(element).to have_link('regular link',    href: wiki.wiki_base_path + '/regular')
        expect(element).to have_link('spaced link',     href: wiki.wiki_base_path + '/title%20with%20spaces')

        expect(element).to have_link('relative link 1', href: relative_path('../relative'))
        expect(element).to have_link('relative link 2', href: relative_path('./relative'))
        expect(element).to have_link('relative link 3', href: relative_path('./e/f/relative'))
      end
    end

    context "when there are no spaces or hyphens in the page name", :js do
      let(:wiki_page) { build(:wiki_page, wiki: wiki, title: 'a/b/c/d', content: page_content) }

      it_behaves_like 'rewrites relative links'
    end

    context "when there are spaces in the page name", :js do
      let(:wiki_page) { build(:wiki_page, wiki: wiki, title: 'a page/b page/c page/d page', content: page_content) }

      it_behaves_like 'rewrites relative links'
    end

    context "when there are hyphens in the page name", :js do
      let(:wiki_page) { build(:wiki_page, wiki: wiki, title: 'a-page/b-page/c-page/d-page', content: page_content) }

      it_behaves_like 'rewrites relative links'
    end
  end

  context "when rendering a new wiki page", :js do
    before do
      wiki_page.create # rubocop:disable Rails/SaveBang
      visit wiki_page_path(wiki, wiki_page)
    end

    it_behaves_like 'relative links' do
      let(:element) { page.find('[data-testid="wiki-page-content"]') }
    end
  end

  context "when previewing an existing wiki page", :js do
    let(:preview) { page.find('.md-preview-holder') }

    before do
      wiki_page.create # rubocop:disable Rails/SaveBang
      visit wiki_page_path(wiki, wiki_page, action: :edit)
    end

    it_behaves_like 'relative links' do
      before do
        click_button("Preview")
      end

      let(:element) { preview }
    end

    it 'renders content with CommonMark' do
      # using two `\n` ensures we're sublist to it's own line due
      # to list auto-continue
      fill_in :wiki_content, with: "1. one\n\n  - sublist\n"
      click_button("Preview")

      # the above generates two separate lists (not embedded) in CommonMark
      expect(preview).to have_content("sublist")
      expect(preview).not_to have_xpath("//ol//li//ul")
    end

    it "does not linkify double brackets inside code blocks as expected" do
      fill_in :wiki_content, with: <<-HEREDOC
        `[[do_not_linkify]]`
        ```
        [[also_do_not_linkify]]
        ```
      HEREDOC
      click_button("Preview")

      expect(preview).to have_content("do_not_linkify")
      expect(preview).to have_content('[[do_not_linkify]]')
      expect(preview).to have_content('[[also_do_not_linkify]]')
    end
  end
end
