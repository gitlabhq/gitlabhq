require 'spec_helper'

describe Banzai::Filter::ExternalIssueReferenceFilter do
  include FilterSpecHelper

  def helper
    IssuesHelper
  end

  shared_examples_for "external issue tracker" do
    it_behaves_like 'a reference containing an element node'

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
      issue_id = doc.css('a').first.attr("data-external-issue")

      expect(doc.css('a').first.attr('href'))
        .to eq helper.url_for_issue(issue_id, project)
    end

    it 'links to the external tracker' do
      doc = filter("Issue #{reference}")

      link = doc.css('a').first.attr('href')
      issue_id = doc.css('a').first.attr("data-external-issue")

      expect(link).to eq(helper.url_for_issue(issue_id, project))
    end

    it 'links with adjacent text' do
      doc = filter("Issue (#{reference}.)")

      expect(doc.to_html).to match(%r{\(<a.+>#{reference}</a>\.\)})
    end

    it 'includes a title attribute' do
      doc = filter("Issue #{reference}")
      expect(doc.css('a').first.attr('title')).to include("Issue in #{project.issues_tracker.title}")
    end

    it 'escapes the title attribute' do
      allow(project.external_issue_tracker).to receive(:title)
        .and_return(%{"></a>whatever<a title="})

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
      issue_id = doc.css('a').first["data-external-issue"]

      expect(link).to eq helper.url_for_issue(issue_id, project, only_path: true)
    end

    context 'with RequestStore enabled' do
      let(:reference_filter) { HTML::Pipeline.new([described_class]) }

      before do
        allow(RequestStore).to receive(:active?).and_return(true)
      end

      it 'queries the collection on the first call' do
        expect_any_instance_of(Project).to receive(:default_issues_tracker?).once.and_call_original
        expect_any_instance_of(Project).to receive(:external_issue_reference_pattern).once.and_call_original

        not_cached = reference_filter.call("look for #{reference}", { project: project })

        expect_any_instance_of(Project).not_to receive(:default_issues_tracker?)
        expect_any_instance_of(Project).not_to receive(:external_issue_reference_pattern)

        cached = reference_filter.call("look for #{reference}", { project: project })

        # Links must be the same
        expect(cached[:output].css('a').first[:href]).to eq(not_cached[:output].css('a').first[:href])
      end
    end
  end

  context "redmine project" do
    let(:project) { create(:redmine_project) }
    let(:issue) { ExternalIssue.new("#123", project) }
    let(:reference) { issue.to_reference }

    before do
      project.issues_enabled = false
      project.save!
    end

    it_behaves_like "external issue tracker"
  end

  context "jira project" do
    let(:project) { create(:jira_project) }
    let(:reference) { issue.to_reference }

    context "with right markdown" do
      let(:issue) { ExternalIssue.new("JIRA-123", project) }

      it_behaves_like "external issue tracker"
    end

    context "with wrong markdown" do
      let(:issue) { ExternalIssue.new("#123", project) }

      it "ignores reference" do
        exp = act = "Issue #{reference}"
        expect(filter(act).to_html).to eq exp
      end
    end
  end
end
