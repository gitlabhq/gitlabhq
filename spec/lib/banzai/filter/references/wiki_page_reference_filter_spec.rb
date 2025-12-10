# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::References::WikiPageReferenceFilter, feature_category: :wiki do
  include FilterSpecHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:cross_namespace) { create(:namespace, name: 'cross-namespace') }
  let_it_be(:project) { create(:project, :public, namespace: namespace) }
  let_it_be(:cross_project) { create(:project, :public, namespace: cross_namespace, path: 'cross-project') }
  let_it_be(:wiki) { ProjectWiki.new(project, user) }
  let_it_be(:wiki_page) { create(:wiki_page, wiki: wiki, title: 'nested/twice/start-page') }
  let_it_be(:cross_wiki) { ProjectWiki.new(cross_project, user) }
  let_it_be_with_reload(:cross_wiki_page) { create(:wiki_page, wiki: cross_wiki, title: 'nested/twice/start-page') }

  shared_examples 'a wiki page reference' do
    it_behaves_like 'a reference containing an element node'

    it 'links to a valid reference' do
      doc = reference_filter("Fixed #{written_reference}")

      expect(doc.css('a').first.attr('href')).to eq wiki_page_url
    end

    it 'links with adjacent text' do
      doc = reference_filter("Fixed (#{written_reference}.)")

      expect(doc.text).to match(%r{^Fixed \(.*\.\)})
    end

    it 'includes a title attribute' do
      doc = reference_filter("Created #{written_reference}")

      expect(doc.css('a').first.attr('title')).to eq wiki_page.title
    end

    it 'escapes the title attribute' do
      title = %("></a>whatever<a title=")
      allow_next_instance_of(WikiPage) do |instance|
        allow(instance).to receive(:title).and_return(title)
      end

      doc = reference_filter("Created #{written_reference}")

      # The full title text should appear in the visible textual content of the page.
      # If it doesn't, it suggests it has affected the parse.
      expect(doc.text).to include title

      # There should be no indication that any of the text has escaped into HTML.
      expect(doc.to_html).not_to include('"></a')
      expect(doc.to_html).not_to include('whatever<a')
    end

    it 'renders non-HTML tooltips' do
      doc = reference_filter("Created #{written_reference}")

      expect(doc.at_css('a')).not_to have_attribute('data-html')
    end

    it 'includes default classes' do
      doc = reference_filter("Created #{written_reference}")
      expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-wiki_page has-tooltip'
    end

    it 'includes a data-issue attribute' do
      doc = reference_filter("See #{written_reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-wiki-page')
      expect(link.attr('data-wiki-page')).to eq wiki_page.slug
    end

    it 'includes a data-original attribute' do
      doc = reference_filter("See #{written_reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-original')
      expect(link.attr('data-original')).to eq inner_text
    end

    it 'does not escape the data-original attribute' do
      skip if written_reference.start_with?('<a')

      inner_html = 'element <code>node</code> inside'
      doc = reference_filter(%(<a href="#{written_reference}">#{inner_html}</a>))

      expect(doc.children.first.children.first.attr('data-original')).to eq inner_html
    end

    it 'does not process links containing issue numbers followed by text' do
      href = "#{written_reference}st"
      doc = reference_filter("<a href='#{href}'></a>")
      link = doc.css('a').first.attr('href')

      expect(link).to eq(href)
    end
  end

  context 'when project level wiki page URL reference' do
    let_it_be(:wiki_page_link_reference)  { urls.project_wiki_url(project, wiki_page) }
    let_it_be(:wiki_page_url)             { wiki_page_link_reference }
    let_it_be(:reference)                 { wiki_page_url }
    let_it_be(:written_reference)         { reference }
    let_it_be(:inner_text)                { written_reference }

    it_behaves_like 'a wiki page reference'
  end

  context 'when project level wiki page full reference' do
    let_it_be(:wiki_page_link_reference)  { urls.project_wiki_url(project, wiki_page) }
    let_it_be(:wiki_page_url)             { wiki_page_link_reference }
    let_it_be(:reference)                 { wiki_page.to_reference(full: true) }
    let_it_be(:written_reference)         { reference }
    let_it_be(:inner_text)                { written_reference }

    it_behaves_like 'a wiki page reference'
  end

  context 'on [wiki_page:XXX] reference' do
    let_it_be(:written_reference)         { "[wiki_page:#{wiki_page.slug}]" }
    let_it_be(:reference)                 { written_reference }
    let_it_be(:inner_text)                { written_reference }
    let_it_be(:wiki_page_link_reference)  { urls.project_wiki_url(project, wiki_page) }
    let_it_be(:wiki_page_url)             { wiki_page_link_reference }

    it_behaves_like 'a wiki page reference'
  end

  context 'on cross project [wiki_page:project/path:slug] reference' do
    let_it_be(:wiki_page_link_reference)  { urls.project_wiki_url(cross_project, wiki_page) }
    let_it_be(:wiki_page_url)             { wiki_page_link_reference }
    let_it_be(:written_reference)         { "[wiki_page:#{cross_project.full_path}:#{cross_wiki_page.slug}]" }
    let_it_be(:reference)                 { written_reference }
    let_it_be(:inner_text)                { written_reference }

    it_behaves_like 'a wiki page reference'
  end

  # Example:
  #   "See http://localhost/cross-namespace/cross-project/-/wikis/foobar"
  context 'when cross-project URL reference' do
    let_it_be(:wiki_page_link_reference)  { urls.project_wiki_url(cross_project, wiki_page) }
    let_it_be(:wiki_page_url)             { wiki_page_link_reference }
    let_it_be(:reference)                 { wiki_page_url }
    let_it_be(:written_reference)         { reference }
    let_it_be(:inner_text)                { written_reference }

    it_behaves_like 'a wiki page reference'

    it 'includes a data-project attribute' do
      doc = reference_filter("Created #{written_reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-project')
      expect(link.attr('data-project')).to eq cross_project.id.to_s
    end
  end
end
