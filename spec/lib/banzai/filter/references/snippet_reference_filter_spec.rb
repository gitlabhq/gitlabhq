# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::References::SnippetReferenceFilter, feature_category: :markdown do
  include FilterSpecHelper

  let(:project)   { create(:project, :public) }
  let(:snippet)   { create(:project_snippet, project: project) }
  let(:reference) { snippet.to_reference }

  it 'requires project context' do
    expect { described_class.call('') }.to raise_error(ArgumentError, /:project/)
  end

  %w[pre code a style].each do |elem|
    it "ignores valid references contained inside '#{elem}' element" do
      act = "<#{elem}>Snippet #{reference}</#{elem}>"
      expect(reference_filter(act).to_html).to include act
    end
  end

  context 'internal reference' do
    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls
        .project_snippet_url(project, snippet)
    end

    it 'links with adjacent text' do
      doc = reference_filter("Snippet (#{reference}.)")
      expect(doc.to_html).to match(%r{\(<a.+>#{Regexp.escape(reference)}</a>\.\)})
    end

    it 'ignores invalid snippet IDs' do
      act = "Snippet #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to include act
    end

    it 'includes a title attribute' do
      doc = reference_filter("Snippet #{reference}")
      expect(doc.css('a').first.attr('title')).to eq snippet.title
    end

    it 'escapes the title attribute' do
      snippet.update_attribute(:title, %("></a>whatever<a title="))

      doc = reference_filter("Snippet #{reference}")
      expect(doc.text).to eq "Snippet #{reference}"
    end

    it 'includes default classes' do
      doc = reference_filter("Snippet #{reference}")
      expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-snippet has-tooltip'
    end

    it 'includes a data-project attribute' do
      doc = reference_filter("Snippet #{reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-project')
      expect(link.attr('data-project')).to eq project.id.to_s
    end

    it 'includes a data-snippet attribute' do
      doc = reference_filter("See #{reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-snippet')
      expect(link.attr('data-snippet')).to eq snippet.id.to_s
    end

    it 'supports an :only_path context' do
      doc = reference_filter("Snippet #{reference}", only_path: true)
      link = doc.css('a').first.attr('href')

      expect(link).not_to match %r{https?://}
      expect(link).to eq urls.project_snippet_url(project, snippet, only_path: true)
    end
  end

  context 'cross-project / cross-namespace complete reference' do
    let(:namespace) { create(:namespace) }
    let(:project2)  { create(:project, :public, namespace: namespace) }
    let!(:snippet)  { create(:project_snippet, project: project2) }
    let(:reference) { "#{project2.full_path}$#{snippet.id}" }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href'))
        .to eq urls.project_snippet_url(project2, snippet)
    end

    it 'link has valid text' do
      doc = reference_filter("See (#{reference}.)")

      expect(doc.css('a').first.text).to eql(reference)
    end

    it 'has valid text' do
      doc = reference_filter("See (#{reference}.)")

      expect(doc.text).to eql("See (#{reference}.)")
    end

    it 'ignores invalid snippet IDs on the referenced project' do
      act = "See #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to include act
    end

    it 'ignores when attempting to reference a group with full path' do
      create(:group, name: 'a_group')
      act = "/a_group$12345"

      expect(reference_filter(act).to_html).to include act
    end
  end

  context 'cross-project / same-namespace complete reference' do
    let(:namespace) { create(:namespace) }
    let(:project)   { create(:project, :public, namespace: namespace) }
    let(:project2)  { create(:project, :public, namespace: namespace) }
    let!(:snippet)  { create(:project_snippet, project: project2) }
    let(:reference) { "#{project2.full_path}$#{snippet.id}" }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href'))
        .to eq urls.project_snippet_url(project2, snippet)
    end

    it 'link has valid text' do
      doc = reference_filter("See (#{project2.path}$#{snippet.id}.)")

      expect(doc.css('a').first.text).to eql("#{project2.path}$#{snippet.id}")
    end

    it 'has valid text' do
      doc = reference_filter("See (#{project2.path}$#{snippet.id}.)")

      expect(doc.text).to eql("See (#{project2.path}$#{snippet.id}.)")
    end

    it 'ignores invalid snippet IDs on the referenced project' do
      act = "See #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to include act
    end
  end

  context 'cross-project shorthand reference' do
    let(:namespace) { create(:namespace) }
    let(:project)   { create(:project, :public, namespace: namespace) }
    let(:project2)  { create(:project, :public, namespace: namespace) }
    let!(:snippet)  { create(:project_snippet, project: project2) }
    let(:reference) { "#{project2.path}$#{snippet.id}" }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href'))
        .to eq urls.project_snippet_url(project2, snippet)
    end

    it 'link has valid text' do
      doc = reference_filter("See (#{project2.path}$#{snippet.id}.)")

      expect(doc.css('a').first.text).to eql("#{project2.path}$#{snippet.id}")
    end

    it 'has valid text' do
      doc = reference_filter("See (#{project2.path}$#{snippet.id}.)")

      expect(doc.text).to eql("See (#{project2.path}$#{snippet.id}.)")
    end

    it 'ignores invalid snippet IDs on the referenced project' do
      act = "See #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to include act
    end
  end

  context 'cross-project URL reference' do
    let(:namespace) { create(:namespace, name: 'cross-reference') }
    let(:project2)  { create(:project, :public, namespace: namespace) }
    let(:snippet)   { create(:project_snippet, project: project2) }
    let(:reference) { urls.project_snippet_url(project2, snippet) }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href'))
        .to eq urls.project_snippet_url(project2, snippet)
    end

    it 'links with adjacent text' do
      doc = reference_filter("See (#{reference}.)")
      expect(doc.to_html).to match(%r{\(<a.+>#{Regexp.escape(snippet.to_reference(project))}</a>\.\)})
    end

    it 'ignores invalid snippet IDs on the referenced project' do
      act = "See #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to match(%r{<a.+>#{Regexp.escape(invalidate_reference(reference))}</a>})
    end
  end

  context 'group context' do
    it 'links to a valid reference' do
      reference = "#{project.full_path}$#{snippet.id}"

      result = reference_filter("See #{reference}", { project: nil, group: create(:group) })

      expect(result.css('a').first.attr('href')).to eq(urls.project_snippet_url(project, snippet))
    end

    it 'ignores internal references' do
      act = "See $#{snippet.id}"

      expect(reference_filter(act, project: nil, group: create(:group)).to_html).to include act
    end
  end

  context 'checking N+1' do
    let(:namespace2) { create(:namespace) }
    let(:project2)   { create(:project, :public, namespace: namespace2) }
    let(:snippet2)   { create(:project_snippet, project: project2) }
    let(:reference2) { "#{project2.full_path}$#{snippet2.id}" }

    it 'does not have N+1 per multiple references per project', :use_sql_query_cache do
      markdown = "#{reference} $9999990"

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        reference_filter(markdown)
      end

      expect(control.count).to eq 1

      markdown = "#{reference} $9999990 $9999991 $9999992 $9999993 #{reference2} something/cool$12"

      # Since we're not batching snippet queries across projects,
      # we have to account for that.
      # 1 for for routes to find routes.source_id of projects matching paths
      # 1 for projects belonging to the above routes
      # 1 for preloading routes of the projects
      # 1 for loading the namespaces associated to the project
      # 1 for loading the routes associated with the namespace
      # 1x2 for snippets in each project == 2
      # Total = 7
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/330359
      expect do
        reference_filter(markdown)
      end.not_to exceed_all_query_limit(control).with_threshold(6)
    end
  end
end
