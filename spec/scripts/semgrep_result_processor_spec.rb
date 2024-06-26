# frozen_string_literal: true

require 'fast_spec_helper'
require 'webmock/rspec'
require_relative '../../scripts/semgrep_result_processor'

RSpec.describe SemgrepResultProcessor, feature_category: :tooling do
  let(:report_file) { 'spec/fixtures/scripts/gl-sast-report.json' }
  let(:path_line_message_dict) do
    { "bug.rb" => [
      { line: 5,
        message: "Deserializing user-controlled objects can cause vulnerabilities." },
      { line: 10, message: "Deserializing user-controlled objects can cause vulnerabilities." },
      { line: 15, message: "Deserializing user-controlled objects can cause vulnerabilities." },
      { line: 17, message: "Deserializing user-controlled objects can cause vulnerabilities." }
    ] }
  end

  let(:processor) { described_class.new(report_file) }

  before do
    stub_env('CI_PROJECT_DIR', '/tmp/project_dir')
    stub_env('CI_API_V4_URL', 'https://gitlab.com/api/v4')
    stub_env('CI_MERGE_REQUEST_PROJECT_ID', '1234')
    stub_env('CI_MERGE_REQUEST_IID', '1234')
    stub_env('CUSTOM_SAST_RULES_BOT_PAT', 'gl-pat-123')
    stub_env('BOT_USER_ID', '21564538')
    stub_request(:any, /gitlab.com/).to_return(status: 400)
  end

  describe '#execute' do
    around do |example|
      example.run
    rescue SystemExit
    end

    it 'raises an error and prints the error message' do
      allow(processor).to receive(:perform_allowlist_check).and_raise(StandardError, 'Error message here')

      expect { processor.execute }.to raise_error(SystemExit)
    end
  end

  describe '#perform_allowlist_check' do
    let(:original_env) { ENV.to_hash }

    around do |example|
      example.run
    rescue SystemExit
    end

    before do
      stub_env('CI_PROJECT_DIR', '/tmp/not_allowlisted')
    end

    it 'exits on non allowlisted project dir' do
      expect(processor.perform_allowlist_check).to raise_error(SystemExit)
    end
  end

  describe '#get_sast_results' do
    it 'returns hash of findings' do
      expect(processor.get_sast_results).to eq(path_line_message_dict)
    end
  end

  describe '#remove_duplicate_findings' do
    # rubocop:disable Layout/LineLength -- we need the entire message + footer
    let(:existing_comments_response) do
      [
        {
          "id" => 1933334610,
          "type" => "DiffNote",
          "body" => "Deserializing user-controlled objects can cause vulnerabilities.  \n\n  \u003csmall\u003e\n  This AppSec automation is currently under testing.\n  Use ~\"appsec-sast::helpful\" or ~\"appsec-sast::unhelpful\" for quick feedback.\n  For any detailed feedback, [add a comment here](https://gitlab.com/gitlab-com/gl-security/product-security/appsec/sast-custom-rules/-/issues/38).\n  \u003c/small\u003e\n\n  /label ~\"appsec-sast::commented\"",
          "author" => {
            "id" => 21564538
          },
          "position" => {
            "base_sha" => "6135e8352307d2bbd94aee1f335483835efd8b65",
            "start_sha" => "e82e15e57ce4e0f67dd8eeadf38e4b115f0ae487",
            "head_sha" => "ee82e8feb0af93b24b5443c7af4440599756bc1f",
            "old_path" => "bug.rb",
            "new_path" => "bug.rb",
            "position_type" => "text",
            "old_line" => nil,
            "new_line" => 17,
            "line_range" => nil
          }
        }
      ]
    end
    # rubocop:enable Layout/LineLength

    let(:expected_path_line_message_dict) do
      { "bug.rb" => [
        { line: 5, message: "Deserializing user-controlled objects can cause vulnerabilities." },
        { line: 10, message: "Deserializing user-controlled objects can cause vulnerabilities." },
        { line: 15, message: "Deserializing user-controlled objects can cause vulnerabilities." }
      ] }
    end

    it 'deletes already posted finding from hash' do
      allow(processor).to receive(:get_existing_comments).and_return(existing_comments_response)
      result = processor.remove_duplicate_findings(path_line_message_dict)

      expect(result).to eq(expected_path_line_message_dict)
    end
  end

  describe '#create_inline_comments' do
    around do |example|
      example.run
    rescue SystemExit
    end

    it 'handles failed comment post' do
      allow(Net::HTTP).to receive(:post).and_return(Net::HTTPBadRequest.new(nil, 400, 'Bad Request'))

      path_line_message_dict = {
        'file1.rb' => [{ line: 10, message: 'Error message 1' }],
        'file2.rb' => [{ line: 20, message: 'Error message 2' }]
      }

      expect { processor.create_inline_comments(path_line_message_dict) }.to raise_error(SystemExit)
    end
  end

  describe '#get_existing_comments' do
    around do |example|
      example.run
    rescue SystemExit
    end

    it 'handles error response' do
      http_double = instance_double(Net::HTTP)
      allow(http_double).to receive(:start).and_return(Net::HTTPBadRequest.new(nil, 400, 'Bad Request'))

      expect { processor.send(:get_existing_comments) }.to raise_error(SystemExit)
    end
  end

  describe '#populate_commits_from_versions' do
    around do |example|
      example.run
    rescue SystemExit
    end

    it 'handles error response' do
      http_double = instance_double(Net::HTTP)
      allow(http_double).to receive(:start).and_return(Net::HTTPBadRequest.new(nil, 400, 'Bad Request'))

      expect { processor.send(:populate_commits_from_versions) }.to raise_error(SystemExit)
    end
  end

  describe '#post_comment' do
    around do |example|
      example.run
    rescue SystemExit
    end

    it 'handles error response' do
      allow(Net::HTTP).to receive(:post).and_return(Net::HTTPBadRequest.new(nil, 400, 'Bad Request'))

      expect { processor.send(:post_comment, 'Example comment') }.to raise_error(SystemExit)
    end
  end
end
