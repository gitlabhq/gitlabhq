require 'spec_helper'

describe Gitlab::ClosingIssueExtractor, lib: true do
  let(:project)   { create(:project) }
  let(:project2)   { create(:project) }
  let(:issue)     { create(:issue, project: project) }
  let(:issue2)     { create(:issue, project: project2) }
  let(:reference) { issue.to_reference }
  let(:cross_reference) { issue2.to_reference(project) }

  subject { described_class.new(project, project.creator) }

  before do
    project2.team << [project.creator, :master]
  end

  describe "#closed_by_message" do
    context 'with a single reference' do
      it do
        message = "Awesome commit (Closes #{reference})"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Awesome commit (closes #{reference})"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Closed #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "closed #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Closing #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "closing #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Close #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "close #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Awesome commit (Fixes #{reference})"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Awesome commit (fixes #{reference})"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Fixed #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "fixed #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Fixing #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "fixing #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Fix #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "fix #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Awesome commit (Resolves #{reference})"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Awesome commit (resolves #{reference})"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Resolved #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "resolved #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Resolving #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "resolving #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Resolve #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "resolve #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      context 'with an external issue tracker reference' do
        it 'extracts the referenced issue' do
          jira_project = create(:jira_project, name: 'JIRA_EXT1')
          jira_issue = ExternalIssue.new("#{jira_project.name}-1", project: jira_project)
          closing_issue_extractor = described_class.new jira_project
          message = "Resolve #{jira_issue.to_reference}"

          expect(closing_issue_extractor.closed_by_message(message)).to eq([jira_issue])
        end
      end
    end

    context "with a cross-project reference" do
      it do
        message = "Closes #{cross_reference}"
        expect(subject.closed_by_message(message)).to eq([issue2])
      end
    end

    context "with a cross-project URL" do
      it do
        message = "Closes #{urls.namespace_project_issue_url(issue2.project.namespace, issue2.project, issue2)}"
        expect(subject.closed_by_message(message)).to eq([issue2])
      end
    end

    context "with an invalid URL" do
      it do
        message = "Closes https://google.com#{urls.namespace_project_issue_path(issue2.project.namespace, issue2.project, issue2)}"
        expect(subject.closed_by_message(message)).to eq([])
      end
    end

    context 'with multiple references' do
      let(:other_issue) { create(:issue, project: project) }
      let(:third_issue) { create(:issue, project: project) }
      let(:reference2) { other_issue.to_reference }
      let(:reference3) { third_issue.to_reference }

      it 'fetches issues in single line message' do
        message = "Closes #{reference} and fix #{reference2}"

        expect(subject.closed_by_message(message)).
            to match_array([issue, other_issue])
      end

      it 'fetches comma-separated issues references in single line message' do
        message = "Closes #{reference}, closes #{reference2}"

        expect(subject.closed_by_message(message)).
            to match_array([issue, other_issue])
      end

      it 'fetches comma-separated issues numbers in single line message' do
        message = "Closes #{reference}, #{reference2} and #{reference3}"

        expect(subject.closed_by_message(message)).
            to match_array([issue, other_issue, third_issue])
      end

      it 'fetches issues in multi-line message' do
        message = "Awesome commit (closes #{reference})\nAlso fixes #{reference2}"

        expect(subject.closed_by_message(message)).
            to match_array([issue, other_issue])
      end

      it 'fetches issues in hybrid message' do
        message = "Awesome commit (closes #{reference})\n"\
                  "Also fixing issues #{reference2}, #{reference3} and #4"

        expect(subject.closed_by_message(message)).
            to match_array([issue, other_issue, third_issue])
      end

      it "fetches cross-project references" do
        message = "Closes #{reference} and #{cross_reference}"

        expect(subject.closed_by_message(message)).
            to match_array([issue, issue2])
      end

      it "fetches cross-project URL references" do
        message = "Closes #{urls.namespace_project_issue_url(issue2.project.namespace, issue2.project, issue2)} and #{reference}"

        expect(subject.closed_by_message(message)).
            to match_array([issue, issue2])
      end

      it "ignores invalid cross-project URL references" do
        message = "Closes https://google.com#{urls.namespace_project_issue_path(issue2.project.namespace, issue2.project, issue2)} and #{reference}"

        expect(subject.closed_by_message(message)).
            to match_array([issue])
      end
    end
  end

  def urls
    Gitlab::Application.routes.url_helpers
  end
end
