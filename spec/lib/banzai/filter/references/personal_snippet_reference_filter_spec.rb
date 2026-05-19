# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::References::PersonalSnippetReferenceFilter, feature_category: :markdown do
  include FilterSpecHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:snippet) { create(:personal_snippet, :public, author: user) }
  let(:url) { urls.snippet_url(snippet) }
  let(:reference) { snippet.to_reference }

  def context_options(overrides = {})
    { project: nil, user: user, current_user: user, skip_project_check: true }.merge(overrides)
  end

  context 'when feature flag is disabled' do
    before do
      stub_feature_flags(personal_snippet_reference_filters: false)
    end

    it 'does not enrich personal snippet URLs' do
      doc = reference_filter("See #{url}", context_options)

      expect(doc.css('a.gfm').length).to eq(0)
    end

    it 'does not resolve bare text references' do
      doc = reference_filter("See #{reference}", context_options)

      expect(doc.css('a.gfm').length).to eq(0)
    end
  end

  context 'with bare text reference' do
    it 'resolves a bare $N to a personal snippet' do
      doc = reference_filter("See #{reference}", context_options)
      link = doc.css('a.gfm').first

      expect(link).to be_present
      expect(link.attr('href')).to eq(urls.snippet_url(snippet))
      expect(link.attr('title')).to eq(snippet.title)
      expect(link.attr('class')).to include('gfm gfm-snippet')
    end

    it 'uses $N as visible text' do
      doc = reference_filter("See #{reference}", context_options)
      link = doc.css('a.gfm').first

      expect(link.text).to eq(reference)
    end

    it 'includes a data-snippet attribute' do
      doc = reference_filter("See #{reference}", context_options)
      link = doc.css('a.gfm').first

      expect(link.attr('data-snippet')).to eq(snippet.id.to_s)
    end

    it 'links with adjacent text' do
      doc = reference_filter("Snippet (#{reference}.)", context_options)
      link = doc.css('a.gfm').first

      expect(link.text).to eq(reference)
      expect(link.previous.text).to end_with('(')
      expect(link.next.text).to start_with('.)')
    end

    it 'ignores non-existent snippet IDs' do
      doc = reference_filter("See $#{non_existing_record_id}", context_options)

      expect(doc.css('a.gfm').length).to eq(0)
    end

    it 'does not match qualified references like namespace/project$N' do
      project = create(:project, :public)
      doc = reference_filter("See #{project.full_path}$#{snippet.id}", context_options)

      expect(doc.css('a.gfm').length).to eq(0)
    end

    describe 'lookbehind guards against unwanted prefix characters' do
      using RSpec::Parameterized::TableSyntax

      where(:prefix_description, :prefix) do
        'alphanumeric'   | 'foo'
        'hyphenated'     | 'foo-bar'
        'dotted'         | 'foo.bar'
        'underscored'    | '_foo'
        'slash-prefixed' | 'foo/bar'
      end

      with_them do
        it 'does not match' do
          doc = reference_filter("See #{prefix}$#{snippet.id}", context_options)

          expect(doc.css('a.gfm').length).to eq(0)
        end
      end
    end

    it 'escapes the title attribute' do
      malicious_snippet = create(:personal_snippet, :public, author: user, title: %("></a>whatever<a title="))

      doc = reference_filter("See $#{malicious_snippet.id}", context_options)
      link = doc.css('a.gfm').first

      expect(link.attr('title')).to eq(%("></a>whatever<a title="))
    end
  end

  context 'with bare text reference in a project context' do
    let_it_be(:project) { create(:project, :public) }

    it 'resolves a bare $N that is not a project snippet' do
      doc = reference_filter("See #{reference}", project: project, current_user: user)
      link = doc.css('a.gfm').last

      expect(link.attr('data-snippet')).to eq(snippet.id.to_s)
    end

    it 'does not resolve a $N that belongs to the current project' do
      project_snippet = create(:project_snippet, project: project)
      ref = "$#{project_snippet.id}"

      doc = reference_filter("See #{ref}", project: project, current_user: user)

      expect(doc.css('a.gfm').length).to eq(0)
    end
  end

  context 'with bare text reference in a user context (no project or group)' do
    it 'resolves a bare $N' do
      doc = reference_filter("See #{reference}", context_options)
      link = doc.css('a.gfm').first

      expect(link).to be_present
      expect(link.attr('data-snippet')).to eq(snippet.id.to_s)
    end
  end

  context 'with autolinked URL reference' do
    it 'enriches a valid personal snippet URL' do
      doc = reference_filter("See #{url}", context_options)
      link = doc.css('a.gfm').first

      expect(link.attr('href')).to eq(url)
      expect(link.attr('title')).to eq(snippet.title)
      expect(link.attr('class')).to include('gfm gfm-snippet')
    end

    it 'collapses the URL to a $N text reference' do
      doc = reference_filter("See #{url}", context_options)
      link = doc.css('a.gfm').first

      expect(link.text).to eq(snippet.to_reference)
    end

    it 'includes a data-snippet attribute' do
      doc = reference_filter("See #{url}", context_options)
      link = doc.css('a.gfm').first

      expect(link.attr('data-snippet')).to eq(snippet.id.to_s)
    end

    it 'includes a data-reference-type attribute' do
      doc = reference_filter("See #{url}", context_options)
      link = doc.css('a.gfm').first

      expect(link.attr('data-reference-type')).to eq('snippet')
    end

    it 'escapes the title attribute' do
      malicious_snippet = create(:personal_snippet, :public, author: user, title: %("></a>whatever<a title="))
      malicious_url = urls.snippet_url(malicious_snippet)

      doc = reference_filter("See #{malicious_url}", context_options)
      link = doc.css('a.gfm').first

      expect(link.attr('title')).to eq(%("></a>whatever<a title="))
    end
  end

  context 'with manually linked URL reference' do
    it 'preserves custom link text' do
      html = %(<a href="#{url}">My Snippet</a>)
      doc = reference_filter(html, context_options)
      link = doc.css('a').first

      expect(link.text).to eq('My Snippet')
      expect(link.attr('href')).to eq(url)
      expect(link.attr('title')).to eq(snippet.title)
      expect(link.attr('class')).to include('gfm gfm-snippet')
    end
  end

  context 'with URL with anchor' do
    it 'preserves the anchor in the href' do
      url_with_anchor = "#{url}#note_123"
      doc = reference_filter("See #{url_with_anchor}", context_options)
      link = doc.css('a.gfm').first

      expect(link.attr('href')).to eq(url_with_anchor)
    end

    it 'collapses to $N (comment N) text for note anchors' do
      url_with_anchor = "#{url}#note_123"
      doc = reference_filter("See #{url_with_anchor}", context_options)
      link = doc.css('a.gfm').first

      expect(link.text).to eq("#{snippet.to_reference} (comment 123)")
    end
  end

  context 'with only_path option' do
    it 'preserves the original URL in href for link references' do
      doc = reference_filter("See #{url}", context_options(only_path: true))
      link = doc.css('a.gfm').first

      expect(link.attr('href')).to eq(url)
    end

    it 'generates a path-only URL for text references' do
      doc = reference_filter("See #{reference}", context_options(only_path: true))
      link = doc.css('a.gfm').first

      expect(link.attr('href')).not_to match(%r{https?://})
    end
  end

  context 'with invalid references' do
    it 'ignores non-existent snippet IDs in URLs' do
      invalid_url = urls.snippet_url(id: non_existing_record_id)
      doc = reference_filter("See #{invalid_url}", context_options)

      expect(doc.css('a.gfm').length).to eq(0)
    end

    it 'ignores project snippet URLs' do
      project = create(:project, :public)
      project_snippet = create(:project_snippet, project: project)
      project_url = urls.project_snippet_url(project, project_snippet)

      doc = reference_filter("See #{project_url}", context_options)

      expect(doc.css('a.gfm-snippet').length).to eq(0)
    end
  end

  context 'in a project context' do
    let_it_be(:project) { create(:project, :public) }

    it 'enriches personal snippet URLs' do
      doc = reference_filter("See #{url}", project: project, current_user: user)
      link = doc.css('a.gfm').first

      expect(link.attr('href')).to eq(url)
      expect(link.attr('title')).to eq(snippet.title)
    end
  end

  context 'in a group context' do
    let_it_be(:group) { create(:group) }

    it 'enriches personal snippet URLs' do
      doc = reference_filter("See #{url}", context_options(group: group))
      link = doc.css('a.gfm').first

      expect(link.attr('href')).to eq(url)
      expect(link.attr('title')).to eq(snippet.title)
    end
  end

  context 'with N+1 prevention', :use_sql_query_cache do
    let_it_be(:snippet2) { create(:personal_snippet, :public, author: user) }
    let(:url2) { urls.snippet_url(snippet2) }
    let(:reference2) { "$#{snippet2.id}" }

    it 'does not have N+1 for multiple URL references' do
      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        reference_filter("See #{url}", context_options)
      end

      expect do
        reference_filter("See #{url} and #{url2}", context_options)
      end.not_to exceed_all_query_limit(control)
    end

    it 'does not have N+1 for multiple text references' do
      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        reference_filter("See #{reference}", context_options)
      end

      expect do
        reference_filter("See #{reference} and #{reference2}", context_options)
      end.not_to exceed_all_query_limit(control)
    end
  end

  context 'with mixed text and URL references in one document' do
    let_it_be(:snippet2) { create(:personal_snippet, :public, author: user) }
    let(:url2) { urls.snippet_url(snippet2) }

    it 'resolves both text and URL references' do
      doc = reference_filter("See #{reference} and #{url2}", context_options)
      links = doc.css('a.gfm')

      expect(links.length).to eq(2)
      expect(links.map { |l| l.attr('data-snippet') }).to contain_exactly(snippet.id.to_s, snippet2.id.to_s)
    end
  end

  context 'with full pipeline integration with SnippetReferenceFilter' do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:project_snippet) { create(:project_snippet, project: project) }

    def full_pipeline_filter(text, context = {})
      context.reverse_merge!(project: project, current_user: user)
      context[:render_context] = Banzai::RenderContext.new(context[:project], context[:current_user])

      filters = [
        Banzai::Filter::MarkdownFilter,
        Banzai::Filter::References::SnippetReferenceFilter,
        Banzai::Filter::References::PersonalSnippetReferenceFilter
      ]

      HTML::Pipeline.new(filters, context).to_document(text)
    end

    it 'resolves a project snippet $N via SnippetReferenceFilter, not PersonalSnippetReferenceFilter' do
      doc = full_pipeline_filter("See $#{project_snippet.id}")
      link = doc.css('a.gfm').first

      expect(link).to be_present
      expect(link.attr('data-snippet')).to eq(project_snippet.id.to_s)
      expect(link.attr('data-project')).to eq(project.id.to_s)
    end

    it 'resolves a personal snippet $N via PersonalSnippetReferenceFilter when not in the project' do
      doc = full_pipeline_filter("See #{reference}")
      link = doc.css('a.gfm').first

      expect(link).to be_present
      expect(link.attr('data-snippet')).to eq(snippet.id.to_s)
      expect(link).not_to have_attribute('data-project')
    end

    it 'resolves both project and personal snippet references in the same document' do
      doc = full_pipeline_filter("See $#{project_snippet.id} and #{reference}")
      links = doc.css('a.gfm')

      expect(links.length).to eq(2)

      project_link = links.detect { |l| l.attr('data-snippet') == project_snippet.id.to_s }
      personal_link = links.detect { |l| l.attr('data-snippet') == snippet.id.to_s }

      expect(project_link.attr('data-project')).to eq(project.id.to_s)
      expect(personal_link).not_to have_attribute('data-project')
    end

    it 'resolves a personal snippet URL alongside a project snippet text reference' do
      doc = full_pipeline_filter("See $#{project_snippet.id} and #{url}")
      links = doc.css('a.gfm')

      expect(links.length).to eq(2)

      project_link = links.detect { |l| l.attr('data-snippet') == project_snippet.id.to_s }
      personal_link = links.detect { |l| l.attr('data-snippet') == snippet.id.to_s }

      expect(project_link).to be_present
      expect(personal_link).to be_present
    end
  end
end
