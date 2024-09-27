# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::References::ProjectReferenceFilter, feature_category: :markdown do
  include FilterSpecHelper

  def invalidate_reference(reference)
    reference.reverse.to_s
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
    act = "Hey #{invalidate_reference(reference)}"

    expect(reference_filter(act).to_html).to include(CGI.escapeHTML(act))
  end

  context 'when invalid reference strings are very long' do
    shared_examples_for 'fails fast' do |ref_string|
      it 'fails fast for long strings' do
        # took well under 1 second in CI https://dev.gitlab.org/gitlab/gitlabhq/merge_requests/3267#note_172824
        expect do
          Timeout.timeout(BANZAI_FILTER_TIMEOUT_MAX) { reference_filter(ref_string).to_html }
        end.not_to raise_error
      end
    end

    it_behaves_like 'fails fast', 'A' * 50000
    it_behaves_like 'fails fast', '/a' * 50000
    it_behaves_like 'fails fast', "mailto:#{'a-' * 499_000}@aaaaaaaa..aaaaaaaa.example.com"
  end

  it 'allows references with text after the > character' do
    doc = reference_filter("Hey #{reference}foo")
    expect(doc.css('a').first.attr('href')).to eq urls.project_url(subject)
  end

  %w[pre code a style].each do |elem|
    it "ignores valid references contained inside '#{elem}' element" do
      act = "<#{elem}>Hey #{CGI.escapeHTML(reference)}</#{elem}>"
      expect(reference_filter(act).to_html).to include act
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

  context 'checking N+1' do
    let_it_be(:normal_project)           { create(:project, :public) }
    let_it_be(:group)                    { create(:group) }
    let_it_be(:group_project)            { create(:project, group: group) }
    let_it_be(:nested_group)             { create(:group, :nested) }
    let_it_be(:nested_project)           { create(:project, group: nested_group) }
    let_it_be(:normal_project_reference) { get_reference(normal_project) }
    let_it_be(:group_project_reference)  { get_reference(group_project) }
    let_it_be(:nested_project_reference) { get_reference(nested_project) }

    it 'does not have N+1 per multiple project references', :use_sql_query_cache do
      markdown = normal_project_reference.to_s

      # warm up first
      reference_filter(markdown)

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        reference_filter(markdown)
      end

      expect(control.count).to eq 1

      markdown = "#{normal_project_reference} #{invalidate_reference(normal_project_reference)} #{group_project_reference} #{nested_project_reference}"

      expect do
        reference_filter(markdown)
      end.not_to exceed_all_query_limit(control)
    end
  end

  it_behaves_like 'limits the number of filtered items' do
    let(:text) { "#{reference} #{reference} #{reference}" }
    let(:ends_with) { "</a> #{CGI.escapeHTML(reference)}" }
  end
end
