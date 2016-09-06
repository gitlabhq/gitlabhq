require 'spec_helper'
require 'html/pipeline'

describe Banzai::Filter::LabelReferenceFilter, lib: true do
  include FilterSpecHelper

  let(:project)   { create(:empty_project, :public) }
  let(:label)     { create(:label, project: project) }
  let(:reference) { label.to_reference }

  it 'requires project context' do
    expect { described_class.call('') }.to raise_error(ArgumentError, /:project/)
  end

  %w(pre code a style).each do |elem|
    it "ignores valid references contained inside '#{elem}' element" do
      exp = act = "<#{elem}>Label #{reference}</#{elem}>"
      expect(reference_filter(act).to_html).to eq exp
    end
  end

  it 'includes default classes' do
    doc = reference_filter("Label #{reference}")
    expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-label has-tooltip'
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

  it 'supports an :only_path context' do
    doc = reference_filter("Label #{reference}", only_path: true)
    link = doc.css('a').first.attr('href')

    expect(link).not_to match %r(https?://)
    expect(link).to eq urls.namespace_project_issues_path(project.namespace, project, label_name: label.name)
  end

  describe 'label span element' do
    it 'includes default classes' do
      doc = reference_filter("Label #{reference}")
      expect(doc.css('a span').first.attr('class')).to eq 'label color-label has-tooltip'
    end

    it 'includes a style attribute' do
      doc = reference_filter("Label #{reference}")
      expect(doc.css('a span').first.attr('style')).to match(/\Abackground-color: #\h{6}; color: #\h{6}\z/)
    end
  end

  context 'Integer-based references' do
    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.
        namespace_project_issues_url(project.namespace, project, label_name: label.name)
    end

    it 'links with adjacent text' do
      doc = reference_filter("Label (#{reference}.)")
      expect(doc.to_html).to match(%r(\(<a.+><span.+>#{label.name}</span></a>\.\)))
    end

    it 'ignores invalid label IDs' do
      exp = act = "Label #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to eq exp
    end
  end

  context 'String-based single-word references' do
    let(:label)     { create(:label, name: 'gfm', project: project) }
    let(:reference) { "#{Label.reference_prefix}#{label.name}" }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.
        namespace_project_issues_url(project.namespace, project, label_name: label.name)
      expect(doc.text).to eq 'See gfm'
    end

    it 'links with adjacent text' do
      doc = reference_filter("Label (#{reference}).")
      expect(doc.to_html).to match(%r(\(<a.+><span.+>#{label.name}</span></a>\)\.))
    end

    it 'ignores invalid label names' do
      exp = act = "Label #{Label.reference_prefix}#{label.name.reverse}"

      expect(reference_filter(act).to_html).to eq exp
    end
  end

  context 'String-based single-word references that begin with a digit' do
    let(:label)     { create(:label, name: '2fa', project: project) }
    let(:reference) { "#{Label.reference_prefix}#{label.name}" }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.
        namespace_project_issues_url(project.namespace, project, label_name: label.name)
      expect(doc.text).to eq 'See 2fa'
    end

    it 'links with adjacent text' do
      doc = reference_filter("Label (#{reference}).")
      expect(doc.to_html).to match(%r(\(<a.+><span.+>#{label.name}</span></a>\)\.))
    end

    it 'ignores invalid label names' do
      exp = act = "Label #{Label.reference_prefix}#{label.id}#{label.name.reverse}"

      expect(reference_filter(act).to_html).to eq exp
    end
  end

  context 'String-based single-word references with special characters' do
    let(:label)     { create(:label, name: '?g.fm&', project: project) }
    let(:reference) { "#{Label.reference_prefix}#{label.name}" }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.
        namespace_project_issues_url(project.namespace, project, label_name: label.name)
      expect(doc.text).to eq 'See ?g.fm&'
    end

    it 'links with adjacent text' do
      doc = reference_filter("Label (#{reference}).")
      expect(doc.to_html).to match(%r(\(<a.+><span.+>\?g\.fm&amp;</span></a>\)\.))
    end

    it 'ignores invalid label names' do
      act = "Label #{Label.reference_prefix}#{label.name.reverse}"
      exp = "Label #{Label.reference_prefix}&amp;mf.g?"

      expect(reference_filter(act).to_html).to eq exp
    end
  end

  context 'String-based multi-word references in quotes' do
    let(:label)     { create(:label, name: 'gfm references', project: project) }
    let(:reference) { label.to_reference(format: :name) }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.
        namespace_project_issues_url(project.namespace, project, label_name: label.name)
      expect(doc.text).to eq 'See gfm references'
    end

    it 'links with adjacent text' do
      doc = reference_filter("Label (#{reference}.)")
      expect(doc.to_html).to match(%r(\(<a.+><span.+>#{label.name}</span></a>\.\)))
    end

    it 'ignores invalid label names' do
      exp = act = %(Label #{Label.reference_prefix}"#{label.name.reverse}")

      expect(reference_filter(act).to_html).to eq exp
    end
  end

  context 'String-based multi-word references that begin with a digit' do
    let(:label)     { create(:label, name: '2 factor authentication', project: project) }
    let(:reference) { label.to_reference(format: :name) }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.
        namespace_project_issues_url(project.namespace, project, label_name: label.name)
      expect(doc.text).to eq 'See 2 factor authentication'
    end

    it 'links with adjacent text' do
      doc = reference_filter("Label (#{reference}.)")
      expect(doc.to_html).to match(%r(\(<a.+><span.+>#{label.name}</span></a>\.\)))
    end

    it 'ignores invalid label names' do
      exp = act = "Label #{Label.reference_prefix}#{label.id}#{label.name.reverse}"

      expect(reference_filter(act).to_html).to eq exp
    end
  end

  context 'String-based multi-word references with special characters in quotes' do
    let(:label)     { create(:label, name: 'g.fm & references?', project: project) }
    let(:reference) { label.to_reference(format: :name) }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.
        namespace_project_issues_url(project.namespace, project, label_name: label.name)
      expect(doc.text).to eq 'See g.fm & references?'
    end

    it 'links with adjacent text' do
      doc = reference_filter("Label (#{reference}.)")
      expect(doc.to_html).to match(%r(\(<a.+><span.+>g\.fm &amp; references\?</span></a>\.\)))
    end

    it 'ignores invalid label names' do
      act = %(Label #{Label.reference_prefix}"#{label.name.reverse}")
      exp = %(Label #{Label.reference_prefix}"?secnerefer &amp; mf.g\")

      expect(reference_filter(act).to_html).to eq exp
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

        expect(doc.css('a').map { |a| a.attr('href') }).to match_array([
          urls.namespace_project_issues_url(project.namespace, project, label_name: bug.name),
          urls.namespace_project_issues_url(project.namespace, project, label_name: feature_proposal.name),
          urls.namespace_project_issues_url(project.namespace, project, label_name: technical_debt.name)
        ])
        expect(doc.text).to eq 'See bug, feature proposal, technical debt'
      end
    end

    context 'separated with a space' do
      let(:references) { "#{bug_reference} #{feature_proposal_reference} #{technical_debt_reference}" }

      it 'links to valid references' do
        doc = reference_filter("See #{references}")

        expect(doc.css('a').map { |a| a.attr('href') }).to match_array([
          urls.namespace_project_issues_url(project.namespace, project, label_name: bug.name),
          urls.namespace_project_issues_url(project.namespace, project, label_name: feature_proposal.name),
          urls.namespace_project_issues_url(project.namespace, project, label_name: technical_debt.name)
        ])
        expect(doc.text).to eq 'See bug feature proposal technical debt'
      end
    end
  end

  describe 'edge cases' do
    it 'gracefully handles non-references matching the pattern' do
      exp = act = '(format nil "~0f" 3.0) ; 3.0'
      expect(reference_filter(act).to_html).to eq exp
    end
  end

  describe 'referencing a label in a link href' do
    let(:reference) { %Q{<a href="#{label.to_reference}">Label</a>} }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.
        namespace_project_issues_url(project.namespace, project, label_name: label.name)
    end

    it 'links with adjacent text' do
      doc = reference_filter("Label (#{reference}.)")
      expect(doc.to_html).to match(%r(\(<a.+>Label</a>\.\)))
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

  describe 'cross project label references' do
    context 'valid project referenced' do
      let(:another_project)  { create(:empty_project, :public) }
      let(:project_name) { another_project.name_with_namespace }
      let(:label) { create(:label, project: another_project, color: '#00ff00') }
      let(:reference) { label.to_reference(project) }

      let!(:result) { reference_filter("See #{reference}") }

      it 'points to referenced project issues page' do
        expect(result.css('a').first.attr('href'))
          .to eq urls.namespace_project_issues_url(another_project.namespace,
                                                   another_project,
                                                   label_name: label.name)
      end

      it 'has valid color' do
        expect(result.css('a span').first.attr('style'))
          .to match /background-color: #00ff00/
      end

      it 'contains cross project content' do
        expect(result.css('a').first.text).to eq "#{label.name} in #{project_name}"
      end
    end

    context 'project that does not exist referenced' do
      let(:result) { reference_filter('aaa/bbb~ccc') }

      it 'does not link reference' do
        expect(result.to_html).to eq 'aaa/bbb~ccc'
      end
    end
  end
end
