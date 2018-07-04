require 'spec_helper'

describe Banzai::Filter::ProjectReferenceFilter do
  include FilterSpecHelper

  def invalidate_reference(reference)
    "#{reference.reverse}"
  end

  def get_reference(project)
    project.to_reference_with_postfix
  end

  let(:project)   { create(:project, :public) }
  subject { project }
  let(:subject_name) { "project" }
  let(:reference) { get_reference(project) }

  it_behaves_like 'user reference or project reference'

  it 'ignores invalid projects' do
    exp = act = "Hey #{invalidate_reference(reference)}"

    expect(reference_filter(act).to_html).to eq(CGI.escapeHTML(exp))
  end

  it 'allows references with text after the > character' do
    doc = reference_filter("Hey #{reference}foo")
    expect(doc.css('a').first.attr('href')).to eq urls.project_url(subject)
  end

  %w(pre code a style).each do |elem|
    it "ignores valid references contained inside '#{elem}' element" do
      exp = act = "<#{elem}>Hey #{CGI.escapeHTML(reference)}</#{elem}>"
      expect(reference_filter(act).to_html).to eq exp
    end
  end

  it 'includes default classes' do
    doc = reference_filter("Hey #{reference}")
    expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-project has-tooltip'
  end

  context 'in group context' do
    let(:group) { create(:group) }
    let(:project) { create(:project, group: group) }

    let(:nested_group) { create(:group, :nested) }
    let(:nested_project) { create(:project, group: nested_group) }

    it 'supports mentioning a project' do
      reference = get_reference(project)
      doc = reference_filter("Hey #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.project_url(project)
    end

    it 'supports mentioning a project in a nested group' do
      reference = get_reference(nested_project)
      doc = reference_filter("Hey #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.project_url(nested_project)
    end
  end

  describe '#projects_hash' do
    it 'returns a Hash containing all Projects' do
      document = Nokogiri::HTML.fragment("<p>#{get_reference(project)}</p>")
      filter = described_class.new(document, project: project)

      expect(filter.projects_hash).to eq({ project.full_path => project })
    end
  end

  describe '#projects' do
    it 'returns the projects mentioned in a document' do
      document = Nokogiri::HTML.fragment("<p>#{get_reference(project)}</p>")
      filter = described_class.new(document, project: project)

      expect(filter.projects).to eq([project.full_path])
    end
  end
end
