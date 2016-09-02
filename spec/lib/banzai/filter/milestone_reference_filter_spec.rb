require 'spec_helper'

describe Banzai::Filter::MilestoneReferenceFilter, lib: true do
  include FilterSpecHelper

  let(:project)   { create(:project, :public) }
  let(:milestone) { create(:milestone, project: project) }
  let(:reference) { milestone.to_reference }

  it 'requires project context' do
    expect { described_class.call('') }.to raise_error(ArgumentError, /:project/)
  end

  %w(pre code a style).each do |elem|
    it "ignores valid references contained inside '#{elem}' element" do
      exp = act = "<#{elem}>milestone #{milestone.to_reference}</#{elem}>"
      expect(reference_filter(act).to_html).to eq exp
    end
  end

  it 'includes default classes' do
    doc = reference_filter("Milestone #{reference}")
    expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-milestone has-tooltip'
  end

  it 'includes a data-project attribute' do
    doc = reference_filter("Milestone #{reference}")
    link = doc.css('a').first

    expect(link).to have_attribute('data-project')
    expect(link.attr('data-project')).to eq project.id.to_s
  end

  it 'includes a data-milestone attribute' do
    doc = reference_filter("See #{reference}")
    link = doc.css('a').first

    expect(link).to have_attribute('data-milestone')
    expect(link.attr('data-milestone')).to eq milestone.id.to_s
  end

  it 'supports an :only_path context' do
    doc = reference_filter("Milestone #{reference}", only_path: true)
    link = doc.css('a').first.attr('href')

    expect(link).not_to match %r(https?://)
    expect(link).to eq urls.
      namespace_project_milestone_path(project.namespace, project, milestone)
  end

  context 'Integer-based references' do
    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.
        namespace_project_milestone_url(project.namespace, project, milestone)
    end

    it 'links with adjacent text' do
      doc = reference_filter("Milestone (#{reference}.)")
      expect(doc.to_html).to match(%r(\(<a.+>#{milestone.name}</a>\.\)))
    end

    it 'ignores invalid milestone IIDs' do
      exp = act = "Milestone #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to eq exp
    end
  end

  context 'String-based single-word references' do
    let(:milestone) { create(:milestone, name: 'gfm', project: project) }
    let(:reference) { "#{Milestone.reference_prefix}#{milestone.name}" }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.
        namespace_project_milestone_url(project.namespace, project, milestone)
      expect(doc.text).to eq 'See gfm'
    end

    it 'links with adjacent text' do
      doc = reference_filter("Milestone (#{reference}.)")
      expect(doc.to_html).to match(%r(\(<a.+>#{milestone.name}</a>\.\)))
    end

    it 'ignores invalid milestone names' do
      exp = act = "Milestone #{Milestone.reference_prefix}#{milestone.name.reverse}"

      expect(reference_filter(act).to_html).to eq exp
    end
  end

  context 'String-based multi-word references in quotes' do
    let(:milestone) { create(:milestone, name: 'gfm references', project: project) }
    let(:reference) { milestone.to_reference(format: :name) }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.
        namespace_project_milestone_url(project.namespace, project, milestone)
      expect(doc.text).to eq 'See gfm references'
    end

    it 'links with adjacent text' do
      doc = reference_filter("Milestone (#{reference}.)")
      expect(doc.to_html).to match(%r(\(<a.+>#{milestone.name}</a>\.\)))
    end

    it 'ignores invalid milestone names' do
      exp = act = %(Milestone #{Milestone.reference_prefix}"#{milestone.name.reverse}")

      expect(reference_filter(act).to_html).to eq exp
    end
  end

  describe 'referencing a milestone in a link href' do
    let(:reference) { %Q{<a href="#{milestone.to_reference}">Milestone</a>} }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.
        namespace_project_milestone_url(project.namespace, project, milestone)
    end

    it 'links with adjacent text' do
      doc = reference_filter("Milestone (#{reference}.)")
      expect(doc.to_html).to match(%r(\(<a.+>Milestone</a>\.\)))
    end

    it 'includes a data-project attribute' do
      doc = reference_filter("Milestone #{reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-project')
      expect(link.attr('data-project')).to eq project.id.to_s
    end

    it 'includes a data-milestone attribute' do
      doc = reference_filter("See #{reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-milestone')
      expect(link.attr('data-milestone')).to eq milestone.id.to_s
    end
  end

  describe 'cross project milestone references' do
    let(:another_project)  { create(:empty_project, :public) }
    let(:project_path) { another_project.path_with_namespace }
    let(:milestone) { create(:milestone, project: another_project) }
    let(:reference) { milestone.to_reference(project) }

    let!(:result) { reference_filter("See #{reference}") }

    it 'points to referenced project milestone page' do
      expect(result.css('a').first.attr('href')).to eq urls.
        namespace_project_milestone_url(another_project.namespace,
                                        another_project,
                                        milestone)
    end

    it 'contains cross project content' do
      expect(result.css('a').first.text).to eq "#{milestone.name} in #{project_path}"
    end

    it 'escapes the name attribute' do
      allow_any_instance_of(Milestone).to receive(:title).and_return(%{"></a>whatever<a title="})
      doc = reference_filter("See #{reference}")
      expect(doc.css('a').first.text).to eq "#{milestone.name} in #{project_path}"
    end
  end

  describe 'cross project milestone references' do
    let(:another_project)  { create(:empty_project, :public) }
    let(:project_path) { another_project.path_with_namespace }
    let(:milestone) { create(:milestone, project: another_project) }
    let(:reference) { milestone.to_reference(project) }

    let!(:result) { reference_filter("See #{reference}") }

    it 'points to referenced project milestone page' do
      expect(result.css('a').first.attr('href')).to eq urls.
        namespace_project_milestone_url(another_project.namespace,
                                        another_project,
                                        milestone)
    end

    it 'contains cross project content' do
      expect(result.css('a').first.text).to eq "#{milestone.name} in #{project_path}"
    end

    it 'escapes the name attribute' do
      allow_any_instance_of(Milestone).to receive(:title).and_return(%{"></a>whatever<a title="})
      doc = reference_filter("See #{reference}")
      expect(doc.css('a').first.text).to eq "#{milestone.name} in #{project_path}"
    end
  end
end
