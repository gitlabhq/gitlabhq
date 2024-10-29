# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab'
require 'json'
require_relative '../../../scripts/duo_chat/reporter'

RSpec.describe Reporter, feature_category: :ai_abstraction_layer do
  subject(:reporter) { described_class.new }

  describe '#run', :freeze_time do
    let(:ci_commit_sha) { 'commitsha' }
    let(:ci_pipeline_url) { 'https://gitlab.com/pipeline/url' }
    let(:client) { double }

    before do
      stub_env('CI_COMMIT_SHA', ci_commit_sha)
      stub_env('CI_PIPELINE_URL', ci_pipeline_url)
      stub_env('CI_COMMIT_BRANCH', ci_commit_branch)
      stub_env('CI_DEFAULT_BRANCH', ci_default_branch)

      allow(Gitlab).to receive(:client).and_return(client)
    end

    context 'when the CI pipeline is running with the commit in `master` branch' do
      let(:ci_commit_branch) { 'master' }
      let(:ci_default_branch) { 'master' }
      let(:snippet_web_url) { 'https://gitlab.com/snippet/url' }
      let(:issue_web_url) { 'https://gitlab.com/issue/url' }

      let(:mock_data) do
        [
          {
            "question" => "question1",
            "resource" => "resource",
            "answer" => "answer1",
            "tools_used" => ["foobar tool"],
            "evaluations" => [
              { "model" => "claude-2", "response" => "Grade: CORRECT" },
              { "model" => "text-bison", "response" => "Grade: CORRECT" }
            ]
          }
        ]
      end

      before do
        allow(reporter).to receive(:report_data).and_return(mock_data)
      end

      it 'uploads snippet, creates a report issue and updates the tracking issue' do
        # Uploads the test data as a snippet along with commit sha and pipeline url
        snippet = double(web_url: snippet_web_url) # rubocop: disable RSpec/VerifiedDoubles -- an internal detail of Gitlab gem.
        snippet_content = ::JSON.pretty_generate({
          commit: ci_commit_sha,
          pipeline_url: ci_pipeline_url,
          data: mock_data
        })

        expect(client).to receive(:create_snippet).with(
          described_class::QA_EVALUATION_PROJECT_ID,
          {
            title: Time.now.utc.to_s,
            files: [{ file_path: "#{Time.now.utc.to_i}.json", content: snippet_content }],
            visibility: 'private'
          }
        ).and_return(snippet)

        # Create a new issue for the report
        issue_title = "Report #{Time.now.utc}"
        issue = double(web_url: issue_web_url) # rubocop: disable RSpec/VerifiedDoubles -- an internal detail of Gitlab gem.

        expect(client).to receive(:create_issue).with(
          described_class::QA_EVALUATION_PROJECT_ID,
          issue_title,
          { description: reporter.markdown_report }
        ).and_return(issue)

        # Updates the tracking issue by adding a row that links to the snippet and the issue just created.
        aggregated_report_issue = double(description: "") # rubocop: disable RSpec/VerifiedDoubles -- an internal detail of Gitlab gem.
        allow(client).to receive(:issue).with(
          described_class::QA_EVALUATION_PROJECT_ID,
          described_class::AGGREGATED_REPORT_ISSUE_IID
        ).and_return(aggregated_report_issue)
        row = "\n| #{Time.now.utc} | 1 | 100.0% | 0.0% | 0.0%"
        row << " | #{issue_web_url} | #{snippet_web_url} |"

        expect(client).to receive(:edit_issue).with(
          described_class::QA_EVALUATION_PROJECT_ID,
          described_class::AGGREGATED_REPORT_ISSUE_IID,
          { description: aggregated_report_issue.description + row }
        )

        reporter.run
      end
    end

    context 'when the CI pipeline is not running with the commit in `master` branch' do
      let(:ci_commit_branch) { 'foobar' }
      let(:ci_default_branch) { 'master' }
      let(:qa_eval_report_filename) { 'report.md' }
      let(:merge_request_iid) { "123" }
      let(:ci_project_id) { "456" }
      let(:ci_project_dir) { "/builds/gitlab-org/gitlab" }
      let(:base_dir) { "#{ci_project_dir}/#{qa_eval_report_filename}" }

      before do
        stub_env('QA_EVAL_REPORT_FILENAME', qa_eval_report_filename)
        stub_env('CI_MERGE_REQUEST_IID', merge_request_iid)
        stub_env('CI_PROJECT_ID', ci_project_id)
        stub_env('CI_PROJECT_DIR', ci_project_dir)
      end

      context 'when a note does not already exist' do
        let(:note) { nil }

        it 'saves the report as a markdown file and creates a new MR note containing the report content' do
          expect(File).to receive(:write).with(base_dir, reporter.markdown_report)

          allow(reporter).to receive(:existing_report_note).and_return(note)
          expect(client).to receive(:create_merge_request_note).with(
            ci_project_id,
            merge_request_iid,
            reporter.markdown_report
          )

          reporter.run
        end
      end

      context 'when a note exists' do
        let(:note_id) { "1" }
        let(:note) { double(id: note_id, type: "Note") } # rubocop: disable RSpec/VerifiedDoubles -- an internal detail of Gitlab gem.

        it 'saves the report as a markdown file and updates the existing MR note containing the report content' do
          expect(File).to receive(:write).with(base_dir, reporter.markdown_report)

          allow(reporter).to receive(:existing_report_note).and_return(note)
          expect(client).to receive(:edit_merge_request_note).with(
            ci_project_id,
            merge_request_iid,
            note_id,
            reporter.markdown_report
          )

          reporter.run
        end
      end
    end
  end

  describe '#markdown_report' do
    let(:mock_data) do
      [
        {
          "question" => "question1",
          "resource" => "resource",
          "answer" => "answer1",
          "tools_used" => ["foobar tool"],
          "evaluations" => [
            { "model" => "claude-2", "response" => "Grade: CORRECT" },
            { "model" => "text-bison", "response" => "Grade: CORRECT" }
          ]
        },
        {
          "question" => "question2",
          "resource" => "resource",
          "answer" => "answer2",
          "tools_used" => [],
          "evaluations" => [
            { "model" => "claude-2", "response" => " Grade: INCORRECT" },
            { "model" => "text-bison", "response" => "Grade: INCORRECT" }
          ]
        },
        {
          "question" => "question3",
          "resource" => "resource",
          "answer" => "answer3",
          "tools_used" => [],
          "evaluations" => [
            { "model" => "claude-2", "response" => " Grade: CORRECT" },
            { "model" => "text-bison", "response" => "Grade: INCORRECT" }
          ]
        },
        {
          "question" => "question4",
          "resource" => "resource",
          "answer" => "answer4",
          "tools_used" => [],
          # Note: The first evaluation (claude-2) is considered invalid and ignored.
          "evaluations" => [
            { "model" => "claude-2", "response" => "???" },
            { "model" => "text-bison", "response" => "Grade: CORRECT" }
          ]
        },
        {
          "question" => "question5",
          "resource" => "resource",
          "answer" => "answer5",
          "tools_used" => [],
          # Note: The second evaluation (text-bison) is considered invalid and ignored.
          "evaluations" => [
            { "model" => "claude-2", "response" => " Grade: INCORRECT" },
            { "model" => "text-bison", "response" => "???" }
          ]
        },
        {
          "question" => "question6",
          "resource" => "resource",
          "answer" => "answer6",
          "tools_used" => [],
          # Note: Both evaluations are invalid as they contain neither `CORRECT` nor `INCORRECT`.
          # It should be ignored in the report.
          "evaluations" => [
            { "model" => "claude-2", "response" => "???" },
            { "model" => "text-bison", "response" => "???" }
          ]
        }
      ]
    end

    before do
      allow(reporter).to receive(:report_data).and_return(mock_data)
    end

    it "generates the correct summary stats and uses the correct emoji indicators" do
      expect(reporter.markdown_report).to include "The total number of evaluations: 5"

      expect(reporter.markdown_report).to include "all LLMs graded `CORRECT`: 2 (40.0%)"
      expect(reporter.markdown_report).to include ":white_check_mark: :white_check_mark:"
      expect(reporter.markdown_report).to include ":warning: :white_check_mark:"

      expect(reporter.markdown_report).to include "all LLMs graded `INCORRECT`: 2 (40.0%)"
      expect(reporter.markdown_report).to include ":x: :x:"
      expect(reporter.markdown_report).to include ":x: :warning:"

      expect(reporter.markdown_report).to include "in which LLMs disagreed: 1 (20.0%)"
      expect(reporter.markdown_report).to include ":white_check_mark: :x:"
    end

    it "includes the tools used" do
      expect(reporter.markdown_report).to include "[\"foobar tool\"]"
    end

    context 'when usernames are present' do
      let(:mock_data) do
        [
          {
            "question" => "@user's @root?",
            "resource" => "resource",
            "answer" => "@user2 and @user3",
            "tools_used" => ["foobar tool"],
            "evaluations" => [
              { "model" => "claude-2", "response" => "Grade: CORRECT\n\n@user4" },
              { "model" => "text-bison", "response" => "Grade: CORRECT\n\n@user5" }
            ]
          }
        ]
      end

      it 'quotes the usernames with backticks' do
        expect(reporter.markdown_report).to include "`@root`"
        expect(reporter.markdown_report).to include "`@user`"
        expect(reporter.markdown_report).to include "`@user2`"
        expect(reporter.markdown_report).to include "`@user3`"
        expect(reporter.markdown_report).to include "`@user4`"
        expect(reporter.markdown_report).to include "`@user5`"
      end
    end
  end
end
