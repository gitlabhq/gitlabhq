require 'spec_helper'

describe Banzai::Filter::ExternalIssueReferenceFilter, lib: true do
  include FilterSpecHelper

  def helper
    IssuesHelper
  end

  let(:project) { create(:jira_project) }

  context 'JIRA issue references' do
    let(:issue)     { ExternalIssue.new('JIRA-123', project) }
    let(:reference) { issue.to_reference }

    it 'requires project context' do
      expect { described_class.call('') }.to raise_error(ArgumentError, /:project/)
    end

    %w(pre code a style).each do |elem|
      it "ignores valid references contained inside '#{elem}' element" do
        exp = act = "<#{elem}>Issue #{reference}</#{elem}>"
        expect(filter(act).to_html).to eq exp
      end
    end

    it 'ignores valid references when using default tracker' do
      expect(project).to receive(:default_issues_tracker?).and_return(true)

      exp = act = "Issue #{reference}"
      expect(filter(act).to_html).to eq exp
    end

    it 'links to a valid reference' do
      doc = filter("Issue #{reference}")
      expect(doc.css('a').first.attr('href'))
        .to eq helper.url_for_issue(reference, project)
    end

    it 'links to the external tracker' do
      doc = filter("Issue #{reference}")
      link = doc.css('a').first.attr('href')

      expect(link).to eq "http://jira.example/browse/#{reference}"
    end

    it 'links with adjacent text' do
      doc = filter("Issue (#{reference}.)")
      expect(doc.to_html).to match(/\(<a.+>#{reference}<\/a>\.\)/)
    end

    it 'includes a title attribute' do
      doc = filter("Issue #{reference}")
      expect(doc.css('a').first.attr('title')).to eq "Issue in JIRA tracker"
    end

    it 'escapes the title attribute' do
      allow(project.external_issue_tracker).to receive(:title).
        and_return(%{"></a>whatever<a title="})

      doc = filter("Issue #{reference}")
      expect(doc.text).to eq "Issue #{reference}"
    end

    it 'includes default classes' do
      doc = filter("Issue #{reference}")
      expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-issue has-tooltip'
    end

    it 'supports an :only_path context' do
      doc = filter("Issue #{reference}", only_path: true)
      link = doc.css('a').first.attr('href')

      expect(link).to eq helper.url_for_issue("#{reference}", project, only_path: true)
    end
  end
end
