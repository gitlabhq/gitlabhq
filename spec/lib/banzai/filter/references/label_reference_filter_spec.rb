# frozen_string_literal: true

require 'spec_helper'
require 'html/pipeline'

RSpec.describe Banzai::Filter::References::LabelReferenceFilter, feature_category: :markdown do
  include FilterSpecHelper

  let(:project)   { create(:project, :public, name: 'sample-project') }
  let(:label)     { create(:label, project: project) }
  let(:reference) { label.to_reference }

  it_behaves_like 'HTML text with references' do
    let(:resource) { label }
    let(:resource_text) { resource.title }
  end

  it 'requires project context' do
    expect { described_class.call('') }.to raise_error(ArgumentError, /:project/)
  end

  %w[pre code a style].each do |elem|
    it "ignores valid references contained inside '#{elem}' element" do
      act = "<#{elem}>Label #{reference}</#{elem}>"
      expect(reference_filter(act).to_html).to include act
    end
  end

  it 'includes default classes' do
    doc = reference_filter("Label #{reference}")
    expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-label has-tooltip gl-link gl-label-link'
  end

  it 'avoids N+1 cached queries', :use_sql_query_cache, :request_store do
    # Run this once to establish a baseline
    reference_filter("Label #{reference}")

    control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
      reference_filter("Label #{reference}")
    end

    labels_markdown = Array.new(10, "Label #{reference}").join('\n')

    expect { reference_filter(labels_markdown) }.not_to exceed_all_query_limit(control)
  end

  it 'includes a data-project attribute' do
    doc = reference_filter("Label #{reference}")
    link = doc.css('a').first

    expect(link).to have_attribute('data-project')
    expect(link.attr('data-project')).to eq project.id.to_s
  end

  it 'includes a data-label attribute' do
    doc = reference_filter("See #{reference}")
    link = doc.css('a').first

    expect(link).to have_attribute('data-label')
    expect(link.attr('data-label')).to eq label.id.to_s
  end

  it 'includes protocol when :only_path not present' do
    doc = reference_filter("Label #{reference}")
    link = doc.css('a').first.attr('href')

    expect(link).to match %r{https?://}
  end

  it 'does not include protocol when :only_path true' do
    doc = reference_filter("Label #{reference}", only_path: true)
    link = doc.css('a').first.attr('href')

    expect(link).not_to match %r{https?://}
  end

  it 'links to issue list when :label_url_method is not present' do
    doc = reference_filter("Label #{reference}", only_path: true)
    link = doc.css('a').first.attr('href')

    expect(link).to eq urls.project_issues_path(project, label_name: label.name)
  end

  it 'links to merge request list when `label_url_method: :project_merge_requests_url`' do
    doc = reference_filter("Label #{reference}", { only_path: true, label_url_method: "project_merge_requests_url" })
    link = doc.css('a').first.attr('href')

    expect(link).to eq urls.project_merge_requests_path(project, label_name: label.name)
  end

  context 'project that does not exist referenced' do
    let(:result) { reference_filter('See aaa/bbb~ccc') }

    it 'does not link reference' do
      expect(result.to_html).to include 'See aaa/bbb~ccc'
    end
  end

  describe 'label span element' do
    it 'includes default classes' do
      doc = reference_filter("Label #{reference}")
      expect(doc.css('a span').first.attr('class')).to include 'gl-label-text'
    end

    it 'includes a style attribute' do
      doc = reference_filter("Label #{reference}")
      expect(doc.css('a span').first.attr('style')).to match(/\Abackground-color: #\h{6}\z/)
    end
  end

  context 'Integer-based references' do
    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls
        .project_issues_url(project, label_name: label.name)
    end

    it 'links with adjacent text' do
      doc = reference_filter("Label (#{reference}.)")
      expect(doc.to_html).to match(%r{\(<span.+><a.+><span.+>#{label.name}</span></a></span>\.\)})
    end

    it 'ignores invalid label IDs' do
      act = "Label #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to include act
    end
  end

  context 'String-based single-word references' do
    let(:label)     { create(:label, name: 'gfm', project: project) }
    let(:reference) { "#{Label.reference_prefix}#{label.name}" }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls
        .project_issues_url(project, label_name: label.name)
      expect(doc.text).to eq 'See gfm'
    end

    it 'links with adjacent text' do
      doc = reference_filter("Label (#{reference}).")
      expect(doc.to_html).to match(%r{\(<span.+><a.+><span.+>#{label.name}</span></a></span>\)\.})
    end

    it 'ignores invalid label names' do
      act = "Label #{Label.reference_prefix}#{label.name.reverse}"

      expect(reference_filter(act).to_html).to include act
    end
  end

  context 'String-based single-word references that begin with a digit' do
    let(:label)     { create(:label, name: '2fa', project: project) }
    let(:reference) { "#{Label.reference_prefix}#{label.name}" }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls
        .project_issues_url(project, label_name: label.name)
      expect(doc.text).to eq 'See 2fa'
    end

    it 'links with adjacent text' do
      doc = reference_filter("Label (#{reference}).")
      expect(doc.to_html).to match(%r{\(<span.+><a.+><span.+>#{label.name}</span></a></span>\)\.})
    end

    it 'ignores invalid label names' do
      act = "Label #{Label.reference_prefix}#{label.id}#{label.name.reverse}"

      expect(reference_filter(act).to_html).to include act
    end
  end

  context 'String-based single-word references with special characters' do
    let(:label)     { create(:label, name: '?g.fm&', project: project) }
    let(:reference) { "#{Label.reference_prefix}#{label.name}" }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls
        .project_issues_url(project, label_name: label.name)
      expect(doc.text).to eq 'See ?g.fm&'
    end

    it 'does not include trailing punctuation', :aggregate_failures do
      ['.', ', ok?', '...', '?', '!', ': is that ok?'].each do |trailing_punctuation|
        doc = filter("Label #{reference}#{trailing_punctuation}")
        expect(doc.to_html).to match(%r{<span.+><a.+><span.+>\?g\.fm&amp;</span></a></span>#{Regexp.escape(trailing_punctuation)}})
      end
    end

    it 'ignores invalid label names' do
      act = "Label #{Label.reference_prefix}#{label.name.reverse}"
      exp = "Label #{Label.reference_prefix}&amp;mf.g?"

      expect(reference_filter(act).to_html).to include exp
    end
  end

  context 'String-based multi-word references in quotes' do
    let(:label)     { create(:label, name: 'gfm references', project: project) }
    let(:reference) { label.to_reference(format: :name) }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls
        .project_issues_url(project, label_name: label.name)
      expect(doc.text).to eq 'See gfm references'
    end

    it 'links with adjacent text' do
      doc = reference_filter("Label (#{reference}.)")
      expect(doc.to_html).to match(%r{\(<span.+><a.+><span.+>#{label.name}</span></a></span>\.\)})
    end

    it 'ignores invalid label names' do
      act = %(Label #{Label.reference_prefix}"#{label.name.reverse}")

      expect(reference_filter(act).to_html).to include act
    end
  end

  context 'String-based multi-word references that begin with a digit' do
    let(:label)     { create(:label, name: '2 factor authentication', project: project) }
    let(:reference) { label.to_reference(format: :name) }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls
        .project_issues_url(project, label_name: label.name)
      expect(doc.text).to eq 'See 2 factor authentication'
    end

    it 'links with adjacent text' do
      doc = reference_filter("Label (#{reference}.)")
      expect(doc.to_html).to match(%r{\(<span.+><a.+><span.+>#{label.name}</span></a></span>\.\)})
    end

    it 'ignores invalid label names' do
      act = "Label #{Label.reference_prefix}#{label.id}#{label.name.reverse}"

      expect(reference_filter(act).to_html).to include act
    end
  end

  context 'String-based multi-word references with special characters in quotes' do
    let(:label)     { create(:label, name: 'g.fm & references?', project: project) }
    let(:reference) { label.to_reference(format: :name) }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls
        .project_issues_url(project, label_name: label.name)
      expect(doc.text).to eq 'See g.fm & references?'
    end

    it 'links with adjacent text' do
      doc = reference_filter("Label (#{reference}.)")
      expect(doc.to_html).to match(%r{\(<span.+><a.+><span.+>g\.fm &amp; references\?</span></a></span>\.\)})
    end

    it 'ignores invalid label names' do
      act = %(Label #{Label.reference_prefix}"#{label.name.reverse}")
      exp = %(Label #{Label.reference_prefix}"?secnerefer &amp; mf.g\")

      expect(reference_filter(act).to_html).to include exp
    end
  end

  context 'References with html entities' do
    let!(:label) { create(:label, title: '&lt;html&gt;', project: project) }

    it 'links to a valid reference' do
      doc = reference_filter('See ~"&lt;html&gt;"')

      expect(doc.css('a').first.attr('href')).to eq urls
        .project_issues_url(project, label_name: label.name)
      expect(doc.text).to eq 'See <html>'
    end

    it 'ignores invalid label names and escapes entities' do
      act = %(Label #{Label.reference_prefix}"&lt;non valid&gt;")

      expect(reference_filter(act).to_html).to include act
    end
  end

  describe 'consecutive references' do
    let(:bug) { create(:label, name: 'bug', project: project) }
    let(:feature_proposal) { create(:label, name: 'feature proposal', project: project) }
    let(:technical_debt) { create(:label, name: 'technical debt', project: project) }

    let(:bug_reference) { "#{Label.reference_prefix}#{bug.name}" }
    let(:feature_proposal_reference) { feature_proposal.to_reference(format: :name) }
    let(:technical_debt_reference) { technical_debt.to_reference(format: :name) }

    context 'separated with a comma' do
      let(:references) { "#{bug_reference}, #{feature_proposal_reference}, #{technical_debt_reference}" }

      it 'links to valid references' do
        doc = reference_filter("See #{references}")

        expect(doc.css('a').map { |a| a.attr('href') }).to match_array(
          [
            urls.project_issues_url(project, label_name: bug.name),
            urls.project_issues_url(project, label_name: feature_proposal.name),
            urls.project_issues_url(project, label_name: technical_debt.name)
          ])
        expect(doc.text).to eq 'See bug, feature proposal, technical debt'
      end
    end

    context 'separated with a space' do
      let(:references) { "#{bug_reference} #{feature_proposal_reference} #{technical_debt_reference}" }

      it 'links to valid references' do
        doc = reference_filter("See #{references}")

        expect(doc.css('a').map { |a| a.attr('href') }).to match_array(
          [
            urls.project_issues_url(project, label_name: bug.name),
            urls.project_issues_url(project, label_name: feature_proposal.name),
            urls.project_issues_url(project, label_name: technical_debt.name)
          ])
        expect(doc.text).to eq 'See bug feature proposal technical debt'
      end
    end
  end

  describe 'edge cases' do
    it 'gracefully handles non-references matching the pattern' do
      act = '(format nil "~0f" 3.0) ; 3.0'
      expect(reference_filter(act).to_html).to include act
    end
  end

  describe 'referencing a label in a link href' do
    let(:reference) { %(<a href="#{label.to_reference}">Label</a>) }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls
        .project_issues_url(project, label_name: label.name)
    end

    it 'links with adjacent text' do
      doc = reference_filter("Label (#{reference}.)")
      expect(doc.to_html).to match(%r{\(<span.+><a.+>Label</a></span>\.\)})
    end

    it 'includes a data-project attribute' do
      doc = reference_filter("Label #{reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-project')
      expect(link.attr('data-project')).to eq project.id.to_s
    end

    it 'includes a data-label attribute' do
      doc = reference_filter("See #{reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-label')
      expect(link.attr('data-label')).to eq label.id.to_s
    end
  end

  describe 'group label references' do
    let(:group)       { create(:group) }
    let(:project)     { create(:project, :public, namespace: group) }
    let(:group_label) { create(:group_label, name: 'gfm references', group: group) }

    context 'without project reference' do
      let(:reference) { group_label.to_reference(format: :name) }

      it 'links to a valid reference' do
        doc = reference_filter("See #{reference}", project: project)

        expect(doc.css('a').first.attr('href')).to eq urls
          .project_issues_url(project, label_name: group_label.name)
        expect(doc.text).to eq 'See gfm references'
      end

      it 'links with adjacent text' do
        doc = reference_filter("Label (#{reference}.)")
        expect(doc.to_html).to match(%r{\(<span.+><a.+><span.+>#{group_label.name}</span></a></span>\.\)})
      end

      it 'ignores invalid label names' do
        act = %(Label #{Label.reference_prefix}"#{group_label.name.reverse}")

        expect(reference_filter(act).to_html).to include act
      end
    end

    context 'with project reference' do
      let(:reference) { "#{project.to_reference_base}#{group_label.to_reference(format: :name)}" }

      it 'links to a valid reference' do
        doc = reference_filter("See #{reference}", project: project)

        expect(doc.css('a').first.attr('href')).to eq urls
          .project_issues_url(project, label_name: group_label.name)
        expect(doc.text).to eq "See gfm references"
      end

      it 'links with adjacent text' do
        doc = reference_filter("Label (#{reference}.)")
        expect(doc.to_html).to match(%r{\(<span.+><a.+><span.+>#{group_label.name}</span></a></span>\.\)})
      end

      it 'ignores invalid label names' do
        act = %(Label #{project.to_reference_base}#{Label.reference_prefix}"#{group_label.name.reverse}")

        expect(reference_filter(act).to_html).to include act
      end
    end
  end

  describe 'cross-project / cross-namespace complete reference' do
    let(:project2)  { create(:project) }
    let(:label)     { create(:label, project: project2, color: '#00ff00') }
    let(:reference) { "#{project2.full_path}~#{label.name}" }
    let!(:result)   { reference_filter("See #{reference}") }

    it 'links to a valid reference' do
      expect(result.css('a').first.attr('href'))
        .to eq urls.project_issues_url(project2, label_name: label.name)
    end

    it 'has valid color' do
      expect(result.css('a span').first.attr('style')).to match(/background-color: #00ff00/)
    end

    it 'has valid link text' do
      expect(result.css('a').first.text).to eq "#{label.name} in #{project2.full_name}"
    end

    it 'has valid text' do
      expect(result.text).to eq "See #{label.name} in #{project2.full_name}"
    end

    it 'ignores invalid IDs on the referenced label' do
      act = "See #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to include act
    end
  end

  describe 'cross-project / same-namespace complete reference' do
    let(:namespace) { create(:namespace) }
    let(:project)   { create(:project, namespace: namespace) }
    let(:project2)  { create(:project, namespace: namespace) }
    let(:label)     { create(:label, project: project2, color: '#00ff00') }
    let(:reference) { "#{project2.full_path}~#{label.name}" }
    let!(:result)   { reference_filter("See #{reference}") }

    it 'links to a valid reference' do
      expect(result.css('a').first.attr('href'))
        .to eq urls.project_issues_url(project2, label_name: label.name)
    end

    it 'has valid color' do
      expect(result.css('a span').first.attr('style')).to match(/background-color: #00ff00/)
    end

    it 'has valid link text' do
      expect(result.css('a').first.text).to eq "#{label.name} in #{project2.name}"
    end

    it 'has valid text' do
      expect(result.text).to eq "See #{label.name} in #{project2.name}"
    end

    it 'ignores invalid IDs on the referenced label' do
      act = "See #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to include act
    end
  end

  describe 'cross-project shorthand reference' do
    let(:namespace) { create(:namespace) }
    let(:project)   { create(:project, namespace: namespace) }
    let(:project2)  { create(:project, namespace: namespace) }
    let(:label)     { create(:label, project: project2, color: '#00ff00') }
    let(:reference) { "#{project2.path}~#{label.name}" }
    let!(:result)   { reference_filter("See #{reference}") }

    it 'links to a valid reference' do
      expect(result.css('a').first.attr('href'))
        .to eq urls.project_issues_url(project2, label_name: label.name)
    end

    it 'has valid color' do
      expect(result.css('a span').first.attr('style'))
        .to match(/background-color: #00ff00/)
    end

    it 'has valid link text' do
      expect(result.css('a').first.text).to eq "#{label.name} in #{project2.name}"
    end

    it 'has valid text' do
      expect(result.text).to eq "See #{label.name} in #{project2.name}"
    end

    it 'ignores invalid IDs on the referenced label' do
      act = "See #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to include act
    end
  end

  describe 'cross group label references' do
    let(:group)            { create(:group) }
    let(:project)          { create(:project, :public, namespace: group) }
    let(:another_group)    { create(:group) }
    let(:another_project)  { create(:project, :public, namespace: another_group) }
    let(:group_label)      { create(:group_label, group: another_group, color: '#00ff00') }
    let(:reference)        { "#{another_project.full_path}~#{group_label.name}" }
    let!(:result)          { reference_filter("See #{reference}", project: project) }

    it 'points to referenced project issues page' do
      expect(result.css('a').first.attr('href'))
        .to eq urls.project_issues_url(another_project, label_name: group_label.name)
    end

    it 'has valid color' do
      expect(result.css('a span').first.attr('style'))
        .to match(/background-color: #00ff00/)
    end

    it 'has valid link text' do
      expect(result.css('a').first.text)
        .to eq "#{group_label.name} in #{another_project.full_name}"
    end

    it 'has valid text' do
      expect(result.text)
        .to eq "See #{group_label.name} in #{another_project.full_name}"
    end

    it 'ignores invalid IDs on the referenced label' do
      act = "See #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to include act
    end

    context 'when group name has HTML entities' do
      let(:another_group) { create(:group, name: 'random', path: 'another_group') }

      before do
        another_group.name = "<img src=x onerror=alert(1)>"
        another_group.save!(validate: false)
      end

      it 'escapes the HTML entities' do
        expect(result.text)
          .to eq "See #{group_label.name} in #{another_project.full_name}"
      end
    end
  end

  describe 'cross-project / same-group_label complete reference' do
    let(:group)            { create(:group) }
    let(:project)          { create(:project, :public, namespace: group) }
    let(:another_project)  { create(:project, :public, namespace: group) }
    let(:group_label)      { create(:group_label, group: group, color: '#00ff00') }
    let(:reference)        { "#{another_project.full_path}~#{group_label.name}" }
    let!(:result)          { reference_filter("See #{reference}", project: project) }

    it 'points to referenced project issues page' do
      expect(result.css('a').first.attr('href'))
        .to eq urls.project_issues_url(another_project, label_name: group_label.name)
    end

    it 'has valid color' do
      expect(result.css('a span').first.attr('style'))
        .to match(/background-color: #00ff00/)
    end

    it 'has valid link text' do
      expect(result.css('a').first.text)
        .to eq "#{group_label.name} in #{another_project.name}"
    end

    it 'has valid text' do
      expect(result.text)
        .to eq "See #{group_label.name} in #{another_project.name}"
    end

    it 'ignores invalid IDs on the referenced label' do
      act = "See #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to include act
    end
  end

  describe 'same project / same group_label complete reference' do
    let(:group)       { create(:group) }
    let(:project)     { create(:project, :public, namespace: group) }
    let(:group_label) { create(:group_label, group: group, color: '#00ff00') }
    let(:reference)   { "#{project.full_path}~#{group_label.name}" }
    let!(:result)     { reference_filter("See #{reference}", project: project) }

    it 'points to referenced project issues page' do
      expect(result.css('a').first.attr('href'))
        .to eq urls.project_issues_url(project, label_name: group_label.name)
    end

    it 'has valid color' do
      expect(result.css('a span').first.attr('style'))
        .to match(/background-color: #00ff00/)
    end

    it 'has valid link text' do
      expect(result.css('a').first.text).to eq group_label.name
    end

    it 'has valid text' do
      expect(result.text).to eq "See #{group_label.name}"
    end

    it 'ignores invalid IDs on the referenced label' do
      act = "See #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to include act
    end
  end

  describe 'same project / same group_label shorthand reference' do
    let(:group)       { create(:group) }
    let(:project)     { create(:project, :public, namespace: group) }
    let(:group_label) { create(:group_label, group: group, color: '#00ff00') }
    let(:reference)   { "#{project.path}~#{group_label.name}" }
    let!(:result)     { reference_filter("See #{reference}", project: project) }

    it 'points to referenced project issues page' do
      expect(result.css('a').first.attr('href'))
        .to eq urls.project_issues_url(project, label_name: group_label.name)
    end

    it 'has valid color' do
      expect(result.css('a span').first.attr('style'))
        .to match(/background-color: #00ff00/)
    end

    it 'has valid link text' do
      expect(result.css('a').first.text).to eq group_label.name
    end

    it 'has valid text' do
      expect(result.text).to eq "See #{group_label.name}"
    end

    it 'ignores invalid IDs on the referenced label' do
      act = "See #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to include act
    end
  end

  describe 'group context' do
    let_it_be(:group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:label) { create(:group_label, group: group) }

    it 'points to the page defined in label_url_method' do
      reference = "~#{label.name}"

      result = reference_filter("See #{reference}", { project: nil, group: group, label_url_method: :group_url })

      expect(result.css('a').first.attr('href')).to eq(urls.group_url(group, label_name: label.name))
    end

    it 'finds labels also in ancestor groups' do
      reference = "~#{label.name}"

      result = reference_filter("See #{reference}", { project: nil, group: subgroup, label_url_method: :group_url })

      expect(result.css('a').first.attr('href')).to eq(urls.group_url(subgroup, label_name: label.name))
    end

    it 'points to referenced project issues page' do
      project = create(:project)
      label = create(:label, project: project)
      reference = "#{project.full_path}~#{label.name}"

      result = reference_filter("See #{reference}", { project: nil, group: group })

      expect(result.css('a').first.attr('href')).to eq(urls.project_issues_url(project, label_name: label.name))
      expect(result.css('a').first.text).to eq "#{label.name} in #{project.full_name}"
    end
  end

  shared_examples 'absolute group reference' do
    it 'supports absolute reference' do
      absolute_reference = "/#{reference}"

      result = reference_filter("See #{absolute_reference}", context)

      if context[:label_url_method] == :group_url
        expect(result.css('a').first.attr('href')).to eq(urls.group_url(group, label_name: group_label.name))
      else
        expect(result.css('a').first.attr('href')).to eq(urls.issues_group_url(group, label_name: group_label.name))
      end

      expect(result.css('a').first.attr('data-original')).to eq absolute_reference
      expect(result.content).to eq "See #{group_label.name}"
    end
  end

  shared_examples 'absolute project reference' do
    it 'supports absolute reference' do
      absolute_reference = "/#{reference}"

      result = reference_filter("See #{absolute_reference}", context)

      if context[:label_url_method] == :project_merge_requests_url
        expect(result.css('a').first.attr('href')).to eq(urls.project_merge_requests_url(project, label_name: project_label.name))
      else
        expect(result.css('a').first.attr('href')).to eq(urls.project_issues_url(project, label_name: project_label.name))
      end

      expect(result.css('a').first.attr('data-original')).to eq absolute_reference
      expect(result.content).to eq "See #{project_label.name}"
    end
  end

  describe 'absolute label references' do
    let_it_be(:parent_group)         { create(:group) }
    let_it_be(:group)                { create(:group, parent: parent_group) }
    let_it_be(:project)              { create(:project, :public, group: group) }
    let_it_be(:project_label)        { create(:label, project: project) }
    let_it_be(:group_label)          { create(:group_label, group: group) }
    let_it_be(:parent_group_label)   { create(:group_label, group: parent_group) }
    let_it_be(:another_parent_group) { create(:group) }
    let_it_be(:another_group)        { create(:group, parent: another_parent_group) }
    let_it_be(:another_project)      { create(:project, :public, group: another_group) }

    context 'with a project label' do
      let(:reference) { "#{project.full_path}~#{project_label.name}" }

      it_behaves_like 'absolute project reference' do
        let(:context) { { project: project } }
      end

      it_behaves_like 'absolute project reference' do
        let(:context) { { project: project, label_url_method: :project_merge_requests_url } }
      end
    end

    context 'with a group label' do
      let_it_be(:reference) { "#{group.full_path}~#{group_label.name}" }

      it_behaves_like 'absolute group reference' do
        let(:context) { { project: nil, group: group } }
      end

      it_behaves_like 'absolute group reference' do
        let(:context) { { project: nil, group: group, label_url_method: :group_url } }
      end
    end

    describe 'cross-project absolute reference' do
      let_it_be(:context) { { project: another_project } }

      # a normal cross-project label works fine. So check just the absolute version.
      it_behaves_like 'absolute project reference' do
        let_it_be(:reference) { "#{project.full_path}~#{project_label.name}" }
      end

      it 'does not find label in ancestors' do
        reference = "/#{project.full_path}~#{parent_group_label.name}"
        result = reference_filter("See #{reference}", context)

        expect(result.to_html).to include "See #{reference}"
      end
    end

    describe 'cross-group absolute reference' do
      let_it_be(:context) { { project: nil, group: another_group } }

      it 'can not find the label' do
        reference = "#{another_group.full_path}~#{group_label.name}"
        result = reference_filter("See #{reference}", context)

        expect(result.to_html).to include "See #{reference}"
      end

      it 'finds the label with relative reference' do
        label_name = group_label.name
        reference = "#{group.full_path}~#{label_name}"
        result = reference_filter("See #{reference}", context)

        if context[:label_url_method] == :group_url
          expect(result.css('a').first.attr('href')).to eq(urls.group_url(group, label_name: label_name))
        else
          expect(result.css('a').first.attr('href')).to eq(urls.issues_group_url(group, label_name: label_name))
        end
      end

      it 'finds label in ancestors' do
        label_name = parent_group_label.name
        reference = "#{group.full_path}~#{label_name}"
        result = reference_filter("See #{reference}", context)

        if context[:label_url_method] == :group_url
          expect(result.css('a').first.attr('href')).to eq(urls.group_url(group, label_name: label_name))
        else
          expect(result.css('a').first.attr('href')).to eq(urls.issues_group_url(group, label_name: label_name))
        end
      end

      it 'does not find label in ancestors' do
        reference = "/#{group.full_path}~#{parent_group_label.name}"
        result = reference_filter("See #{reference}", context)

        expect(result.to_html).to include "See #{reference}"
      end

      it_behaves_like 'absolute group reference' do
        let_it_be(:reference) { "#{group.full_path}~#{group_label.name}" }
      end
    end
  end

  context 'when invalid parent used with label_url_method' do
    let_it_be(:group) { create(:group) }
    let(:context) { { project: nil, group: nil } }

    it 'does not raise NoMethodError' do
      context[:label_url_method] = :project_merge_requests_url
      filter = described_class.new(Nokogiri::HTML::DocumentFragment.parse(''), context)

      result = filter.url_for_object(label, group)

      expect(result).to be_nil
    end
  end

  context 'checking N+1' do
    let_it_be(:group)              { create(:group) }
    let_it_be(:group2)             { create(:group) }
    let_it_be(:project)            { create(:project, :public, namespace: group) }
    let_it_be(:project2)           { create(:project, :public, namespace: group2) }
    let_it_be(:project3)           { create(:project, :public) }
    let_it_be(:project_label)      { create(:label, project: project) }
    let_it_be(:project_label2)     { create(:label, project: project) }
    let_it_be(:project2_label)     { create(:label, project: project2) }
    let_it_be(:group2_label)       { create(:group_label, group: group2, color: '#00ff00') }
    let_it_be(:project_reference)  { project_label.to_reference.to_s }
    let_it_be(:project_reference2) { project_label2.to_reference.to_s }
    let_it_be(:project2_reference) { project2_label.to_reference.to_s }
    let_it_be(:group2_reference)   { "#{project2.full_path}~#{group2_label.name}" }

    it 'does not have N+1 per multiple references per project', :use_sql_query_cache do
      markdown = project_reference.to_s
      control_count = 1

      expect do
        reference_filter(markdown)
      end.not_to exceed_all_query_limit(control_count)

      markdown = "#{project_reference} ~qwert ~werty ~ertyu ~rtyui #{project_reference2}"

      expect do
        reference_filter(markdown)
      end.not_to exceed_all_query_limit(control_count)
    end

    it 'has N+1 for multiple unique project/group references', :use_sql_query_cache do
      # reference to already loaded project, only one query
      markdown = project_reference.to_s
      control_count = 1

      expect do
        reference_filter(markdown, project: project)
      end.not_to exceed_all_query_limit(control_count)

      # Since we're not batching label queries across projects/groups,
      # queries increase when a new project/group is added.
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/330359
      # 1 for for routes to find routes.source_id of projects matching paths
      # 1 for projects belonging to the above routes
      # 1 for preloading routes of the projects
      # 1 for loading the namespaces associated to the project
      # 1 for loading the routes associated with the namespace
      # 1 for the group
      # 1x2 for labels
      # Total == 8
      markdown = "#{project_reference} #{group2_reference}"
      max_count = control_count + 7

      expect do
        reference_filter(markdown)
      end.not_to exceed_all_query_limit(max_count)

      # third reference to already queried project/namespace, nothing extra (no N+1 here)
      markdown = "#{project_reference} #{group2_reference} #{project2_reference}"

      expect do
        reference_filter(markdown)
      end.not_to exceed_all_query_limit(max_count)

      # last reference needs another namespace and label query (2)
      markdown = "#{project_reference} #{group2_reference} #{project2_reference} #{project3.full_path}~test_label"
      max_count += 2

      expect do
        reference_filter(markdown)
      end.not_to exceed_all_query_limit(max_count)
    end
  end
end
