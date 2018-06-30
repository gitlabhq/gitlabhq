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
  let(:reference) { get_reference(project) }

  it 'ignores invalid projects' do
    exp = act = "Hey #{invalidate_reference(reference)}"

    expect(reference_filter(act).to_html).to eq(CGI.escapeHTML(exp))
  end

  it 'ignores references with text after the > sign' do
    exp = act = "Hey #{reference}foo"
    expect(reference_filter(act).to_html).to eq CGI.escapeHTML(exp)
  end

  %w(pre code a style).each do |elem|
    it "ignores valid references contained inside '#{elem}' element" do
      exp = act = "<#{elem}>Hey #{CGI.escapeHTML(reference)}</#{elem}>"
      expect(reference_filter(act).to_html).to eq exp
    end
  end

  context 'mentioning a project' do
    it_behaves_like 'a reference containing an element node'

    it 'links to a Project' do
      doc = reference_filter("Hey #{reference}")
      expect(doc.css('a').first.attr('href')).to eq urls.project_url(project)
    end

    it 'links to a Project with a period' do
      project = create(:project, name: 'alphA.Beta')

      doc = reference_filter("Hey #{get_reference(project)}")
      expect(doc.css('a').length).to eq 1
    end

    it 'links to a Project with an underscore' do
      project = create(:project, name: 'ping_pong_king')

      doc = reference_filter("Hey #{get_reference(project)}")
      expect(doc.css('a').length).to eq 1
    end

    it 'links to a Project with different case-sensitivity' do
      project = create(:project, name: 'RescueRanger')
      reference = get_reference(project)

      doc = reference_filter("Hey #{reference.upcase}")
      expect(doc.css('a').length).to eq 1
      expect(doc.css('a').text).to eq(reference)
    end

    it 'includes a data-project attribute' do
      doc = reference_filter("Hey #{reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-project')
      expect(link.attr('data-project')).to eq project.id.to_s
    end
  end

  it 'includes default classes' do
    doc = reference_filter("Hey #{reference}")
    expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-project has-tooltip'
  end

  it 'supports an :only_path context' do
    doc = reference_filter("Hey #{reference}", only_path: true)
    link = doc.css('a').first.attr('href')

    expect(link).not_to match %r(https?://)
    expect(link).to eq urls.project_path(project)
  end

  context 'referencing a project in a link href' do
    let(:reference) { %Q{<a href="#{get_reference(project)}">Project</a>} }

    it 'links to a Project' do
      doc = reference_filter("Hey #{reference}")
      expect(doc.css('a').first.attr('href')).to eq urls.project_url(project)
    end

    it 'links with adjacent text' do
      doc = reference_filter("Mention me (#{reference}.)")
      expect(doc.to_html).to match(%r{\(<a.+>Project</a>\.\)})
    end

    it 'includes a data-project attribute' do
      doc = reference_filter("Hey #{reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-project')
      expect(link.attr('data-project')).to eq project.id.to_s
    end
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
