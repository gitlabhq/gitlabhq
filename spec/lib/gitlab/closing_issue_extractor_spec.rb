# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ClosingIssueExtractor do
  let_it_be(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project) }
  let_it_be_with_reload(:project2) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:issue2) { create(:issue, project: project2) }
  let_it_be(:group_work_item) { create(:work_item, :group_level, namespace: group) }

  let(:reference) { issue.to_reference }
  let(:cross_reference) { issue2.to_reference(project) }

  subject { described_class.new(project, project.creator) }

  before_all do
    project.add_developer(project.creator)
    project.add_developer(project2.creator)
    project2.add_maintainer(project.creator)
    group.add_developer(project.creator)
  end

  describe "#closed_by_message" do
    context 'with a single reference' do
      it do
        message = "Awesome commit (Closes #{reference})"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Awesome commit (Closes: #{reference})"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Awesome commit (closes #{reference})"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Awesome commit (closes: #{reference})"
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
        message = "closed: #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Closing #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Closing: #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "closing #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "closing: #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Close #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Close: #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "close #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "close: #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Awesome commit (Fixes #{reference})"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Awesome commit (fixes: #{reference})"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Awesome commit (fixes #{reference})"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Awesome commit (Fixes: #{reference})"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Fixed #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Fixed: #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "fixed #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "fixed: #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Fixing #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Fixing: #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "fixing #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "fixing: #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Fix #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Fix: #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "fix #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "fix: #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Awesome commit (Resolves #{reference})"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Awesome commit (Resolves: #{reference})"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Awesome commit (resolves #{reference})"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Awesome commit (resolves: #{reference})"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Resolved #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Resolved: #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "resolved #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "resolved: #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Resolving #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Resolving: #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "resolving #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "resolving: #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Resolve #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Resolve: #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "resolve #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "resolve: #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Implement: #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Implements: #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Implemented: #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Implementing: #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "implement: #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "implements: #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "implemented: #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "implementing: #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      context 'with an external issue tracker reference' do
        let_it_be_with_reload(:jira_project) { create(:project, :with_jira_integration, name: 'JIRA_EXT1') }

        let(:jira_issue) { ExternalIssue.new("#{jira_project.name}-1", project: jira_project) }
        let(:message) { "Resolve #{jira_issue.to_reference}" }

        subject { described_class.new(jira_project, jira_project.creator) }

        it 'extracts the referenced issue' do
          expect(subject.closed_by_message(message)).to eq([jira_issue])
        end

        it 'extracts the referenced issue even if GitLab issues are disabled for the project' do
          jira_project.update!(issues_enabled: false)

          expect(subject.closed_by_message(message)).to eq([jira_issue])
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
        message = "Closes #{urls.project_issue_url(issue2.project, issue2)}"
        expect(subject.closed_by_message(message)).to eq([issue2])
      end

      context 'when multiple references are used for the same issue (also as work item)' do
        it 'only returns the same issue once' do
          message =
            "Closes #{urls.project_issue_url(issue2.project, issue2)} " \
            "Closes #{urls.project_work_item_url(issue2.project, issue2)}"
          expect(subject.closed_by_message(message).map(&:id)).to contain_exactly(issue2.id)
        end
      end

      context 'when reference is a group level work item' do
        specify do
          message = "Closes #{Gitlab::UrlBuilder.build(group_work_item)}"
          expect(subject.closed_by_message(message)).to contain_exactly(group_work_item)
        end

        context 'when multiple references are used for the same work item' do
          it 'only returns the same work item once' do
            message =
              "Closes #{Gitlab::UrlBuilder.build(group_work_item)} Closes #{group_work_item.to_reference(full: true)}"
            expect(subject.closed_by_message(message)).to contain_exactly(group_work_item)
          end
        end
      end
    end

    context "with a cross-project fork reference" do
      let(:forked_project) { Projects::ForkService.new(project, project2.creator).execute[:project] }
      let(:fork_cross_reference) { issue.to_reference(forked_project) }

      subject { described_class.new(forked_project, forked_project.creator) }

      it do
        message = "Closes #{fork_cross_reference}"
        expect(subject.closed_by_message(message)).to be_empty
      end
    end

    context 'when target project has autoclose issues disabled' do
      before do
        project2.update!(autoclose_referenced_issues: false)
      end

      it 'still includes the issue reference' do
        message = "Closes #{cross_reference}"
        expect(subject.closed_by_message(message)).to contain_exactly(issue2)
      end
    end

    context 'when target project has issues disabled' do
      before do
        project2.update!(issues_enabled: false)
      end

      it 'omits the issue reference' do
        message = "Closes #{cross_reference}"
        expect(subject.closed_by_message(message)).to be_empty
      end
    end

    context "with an invalid URL" do
      it do
        message = "Closes https://google.com#{urls.project_issue_path(issue2.project, issue2)}"
        expect(subject.closed_by_message(message)).to eq([])
      end
    end

    context "with an invalid keyword such as suffix insted of fix" do
      it do
        message = "suffix #{reference}"
        expect(subject.closed_by_message(message)).to eq([])
      end
    end

    context 'with multiple references' do
      let_it_be(:other_issue) { create(:issue, project: project) }
      let_it_be(:third_issue) { create(:issue, project: project) }

      let(:reference2) { other_issue.to_reference }
      let(:reference3) { third_issue.to_reference }

      it 'fetches issues in single line message' do
        message = "Closes #{reference} and fix #{reference2}"

        expect(subject.closed_by_message(message))
            .to match_array([issue, other_issue])
      end

      it 'fetches comma-separated issues references in single line message' do
        message = "Closes #{reference}, closes #{reference2}"

        expect(subject.closed_by_message(message))
            .to match_array([issue, other_issue])
      end

      it 'fetches comma-separated issues numbers in single line message' do
        message = "Closes #{reference}, #{reference2} and #{reference3}"

        expect(subject.closed_by_message(message))
            .to match_array([issue, other_issue, third_issue])
      end

      it 'allows oxford commas (comma before and) when referencing multiple issues' do
        message = "Closes #{reference}, #{reference2}, and #{reference3}"

        expect(subject.closed_by_message(message))
            .to match_array([issue, other_issue, third_issue])
      end

      it 'allows spaces before commas when referencing multiple issues' do
        message = "Closes #{reference} , #{reference2} , and #{reference3}"

        expect(subject.closed_by_message(message))
            .to match_array([issue, other_issue, third_issue])
      end

      it 'allows non-comma-separated issue numbers in single line message' do
        message = "Closes #{reference} #{reference2} #{reference3}"

        expect(subject.closed_by_message(message))
            .to match_array([issue, other_issue, third_issue])
      end

      it 'allows mixed comma-separated and non-comma-separated issue numbers in single line message' do
        message = "Closes #{reference}, #{reference2} #{reference3}"

        expect(subject.closed_by_message(message))
            .to match_array([issue, other_issue, third_issue])
      end

      it 'fetches issues in multi-line message' do
        message = "Awesome commit (closes #{reference})\nAlso fixes #{reference2}"

        expect(subject.closed_by_message(message))
            .to match_array([issue, other_issue])
      end

      it 'fetches issues in hybrid message' do
        message = "Awesome commit (closes #{reference})\n"\
                  "Also fixing issues #{reference2}, #{reference3} and #4"

        expect(subject.closed_by_message(message))
            .to match_array([issue, other_issue, third_issue])
      end

      it "fetches cross-project references" do
        message = "Closes #{reference} and #{cross_reference}"

        expect(subject.closed_by_message(message))
            .to match_array([issue, issue2])
      end

      it "fetches cross-project URL references" do
        message = "Closes #{urls.project_issue_url(issue2.project, issue2)}, #{reference} and #{urls.project_issue_url(other_issue.project, other_issue)}"

        expect(subject.closed_by_message(message))
            .to match_array([issue, issue2, other_issue])
      end

      it "ignores invalid cross-project URL references" do
        message = "Closes https://google.com#{urls.project_issue_path(issue2.project, issue2)} and #{reference}"

        expect(subject.closed_by_message(message))
            .to match_array([issue])
      end
    end

    context "with autoclose referenced issues disabled" do
      before_all do
        project.update!(autoclose_referenced_issues: false)
      end

      it 'still includes issues from projects that have the setting disabled' do
        message = "Closes #{cross_reference} Closes #{reference}"
        expect(subject.closed_by_message(message)).to contain_exactly(issue, issue2)
      end
    end
  end

  def urls
    Gitlab::Routing.url_helpers
  end
end
