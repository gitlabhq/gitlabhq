# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::References::ProjectReferenceFilter do
  include FilterSpecHelper

  def invalidate_reference(reference)
    "#{reference.reverse}"
  end

  def get_reference(project)
    project.to_reference
  end

  let(:project) { create(:project, :public) }
  subject { project }

  let(:subject_name) { "project" }
  let(:reference) { get_reference(project) }

  it_behaves_like 'user reference or project reference'

  it 'ignores invalid projects' do
    exp = act = "Hey #{invalidate_reference(reference)}"

    expect(reference_filter(act).to_html).to eq(CGI.escapeHTML(exp))
  end

  context 'when invalid reference strings are very long' do
    shared_examples_for 'fails fast' do |ref_string|
      it 'fails fast for long strings' do
        # took well under 1 second in CI https://dev.gitlab.org/gitlab/gitlabhq/merge_requests/3267#note_172824
        expect do
          Timeout.timeout(3.seconds) { reference_filter(ref_string).to_html }
        end.not_to raise_error
      end
    end

    it_behaves_like 'fails fast', 'A' * 50000
    it_behaves_like 'fails fast', '/a' * 50000
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

      expect(filter.send(:projects_hash)).to eq({ project.full_path => project })
    end
  end

  describe '#projects' do
    it 'returns the projects mentioned in a document' do
      document = Nokogiri::HTML.fragment("<p>#{get_reference(project)}</p>")
      filter = described_class.new(document, project: project)

      expect(filter.send(:projects)).to eq([project.full_path])
    end
  end
end
