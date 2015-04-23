require 'spec_helper'

module Gitlab::Markdown
  describe ExternalIssueReferenceFilter do
    include ReferenceFilterSpecHelper

    def helper
      IssuesHelper
    end

    let(:project) { create(:empty_project) }
    let(:issue)   { double('issue', iid: 123) }

    context 'JIRA issue references' do
      let(:reference) { "JIRA-#{issue.iid}" }

      before do
        jira = project.create_jira_service

        props = {
          'title'         => 'JIRA tracker',
          'project_url'   => 'http://jira.example/issues/?jql=project=A',
          'issues_url'    => 'http://jira.example/browse/:id',
          'new_issue_url' => 'http://jira.example/secure/CreateIssue.jspa'
        }

        jira.update_attributes(properties: props, active: true)
      end

      after do
        project.jira_service.destroy
      end

      it 'requires project context' do
        expect { described_class.call('Issue JIRA-123', {}) }.
          to raise_error(ArgumentError, /:project/)
      end

      %w(pre code a style).each do |elem|
        it "ignores valid references contained inside '#{elem}' element" do
          exp = act = "<#{elem}>Issue JIRA-#{issue.iid}</#{elem}>"
          expect(filter(act).to_html).to eq exp
        end
      end

      it 'ignores valid references when using default tracker' do
        expect(project).to receive(:default_issues_tracker?).and_return(true)

        exp = act = "Issue #{reference}"
        expect(filter(act).to_html).to eq exp
      end

      %w(pre code a style).each do |elem|
        it "ignores references contained inside '#{elem}' element" do
          exp = act = "<#{elem}>Issue #{reference}</#{elem}>"
          expect(filter(act).to_html).to eq exp
        end
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
        expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-issue'
      end

      it 'includes an optional custom class' do
        doc = filter("Issue #{reference}", reference_class: 'custom')
        expect(doc.css('a').first.attr('class')).to include 'custom'
      end

      it 'supports an :only_path context' do
        doc = filter("Issue #{reference}", only_path: true)
        link = doc.css('a').first.attr('href')

        expect(link).to eq helper.url_for_issue("#{reference}", project, only_path: true)
      end
    end
  end
end
