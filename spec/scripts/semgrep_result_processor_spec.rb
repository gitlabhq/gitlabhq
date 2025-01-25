# frozen_string_literal: true

require 'fast_spec_helper'
require 'webmock/rspec'
require 'oj'
require_relative '../../scripts/semgrep_result_processor'

RSpec.describe SemgrepResultProcessor, feature_category: :tooling do
  let(:report_file) { 'spec/fixtures/scripts/gl-sast-report.json' }

  let(:processor) { described_class.new(report_file) }

  before do
    stub_env('CI_PROJECT_DIR', '/tmp/project_dir')
    stub_env('CI_API_V4_URL', 'https://gitlab.com/api/v4')
    stub_env('CI_MERGE_REQUEST_PROJECT_ID', '1234')
    stub_env('CI_MERGE_REQUEST_IID', '1234')
    stub_env('CI_MERGE_REQUEST_LABELS', '')
    stub_env('CUSTOM_SAST_RULES_BOT_PAT', 'gl-pat-123')
    stub_env('BOT_USER_ID', '21564538')
    stub_request(:any, /gitlab.com/).to_return(status: 400)
  end

  describe '#execute' do
    around do |example|
      example.run
    rescue SystemExit
    end

    let(:sample_results) do
      {
        "some_fingerprint" => { path: "example_path.rb", line: 1, message: "Example message" }
      }
    end
    let(:unique_results) { sample_results } # Assume filter_duplicate_findings returns the same data for simplicity

    before do
      allow(processor).to receive(:get_sast_results).and_return(sample_results)
      allow(processor).to receive(:filter_duplicate_findings).with(sample_results).and_return(unique_results)
      allow(processor).to receive(:create_inline_comments).with(unique_results)
    end

    it 'calls the methods in the correct sequence with expected arguments' do
      expect(processor).to receive(:perform_allowlist_check)
      expect(processor).to receive(:get_sast_results)
      expect(processor).to receive(:filter_duplicate_findings).with(sample_results)
      expect(processor).to receive(:create_inline_comments).with(unique_results)

      processor.execute
    end

    it 'raises an error and prints the error message' do
      allow(processor).to receive(:perform_allowlist_check).and_raise(StandardError, 'Error message here')

      expect { processor.execute }.to raise_error(SystemExit)
    end

    context 'when CI_MERGE_REQUEST_LABELS includes appsec-sast::stop' do
      it "prints the 'not adding comments' message" do
        stub_env('CI_MERGE_REQUEST_LABELS', 'appsec-sast::stop')

        expect(processor).to receive(:perform_allowlist_check)
        expect(processor).to receive(:get_sast_results)
        expect(processor).to receive(:filter_duplicate_findings).with(sample_results)

        expect do
          processor.execute
        end.to output(/Not adding comments for this MR as it has the appsec-sast::stop label/).to_stdout
      end
    end
  end

  describe '#sast_stop_label_present?' do
    context 'when CI_MERGE_REQUEST_LABELS includes appsec-sast::stop' do
      it 'returns true' do
        stub_env('CI_MERGE_REQUEST_LABELS', 'appsec-sast::stop, other-label')
        expect(processor.sast_stop_label_present?).to be true
      end
    end

    context 'when CI_MERGE_REQUEST_LABELS does not include appsec-sast::stop' do
      it 'returns false' do
        stub_env('CI_MERGE_REQUEST_LABELS', 'another-label, different-label')
        expect(processor.sast_stop_label_present?).to be false
      end
    end

    context 'when CI_MERGE_REQUEST_LABELS is empty' do
      it 'returns false' do
        stub_env('CI_MERGE_REQUEST_LABELS', '')
        expect(processor.sast_stop_label_present?).to be false
      end
    end

    context 'when CI_MERGE_REQUEST_LABELS is nil' do
      it 'returns false' do
        stub_env('CI_MERGE_REQUEST_LABELS', nil)
        expect(processor.sast_stop_label_present?).to be false
      end
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

  describe '#filter_duplicate_findings' do
    before do
      allow(processor).to receive(:get_existing_comments).and_return(existing_comments)
    end

    let(:existing_comments) do
      [
        { "body" => "<!-- {\"fingerprint\":\"abc123\",\"check_id\":\"RULE5\"} --> Some comment ",
          "author" => { "id" => 123 } },
        { "body" => "<!-- {\"fingerprint\":\"def456\",\"check_id\":\"RULE6\"} --> Another comment ",
          "author" => { "id" => 123 } },
        { "body" => "<!-- {\"fingerprint\":\"ghi789\",\"check_id\":\"RULE7\"} --> Yet another comment ",
          "author" => { "id" => 123 } }
      ]
    end

    let(:first_unique_rule_id) { described_class::UNIQUE_COMMENT_RULES_IDS.first }
    let(:new_run_findings) do
      {
        "abc123" => { path: "path/to/file1.rb", line: 10, message: "Duplicate finding 1", check_id: "RULE1" },
        "def456" => { path: "path/to/file2.rb", line: 20, message: "Duplicate finding 2", check_id: "RULE2" },
        "new123" => { path: "path/to/file3.rb", line: 30, message: "New finding 1", check_id: "RULE3" },
        "new456" => { path: "path/to/file4.rb", line: 40, message: "New finding 2", check_id: "RULE4" }
      }
    end

    it 'filters out findings with fingerprints that are already in comments from the bot' do
      result = processor.filter_duplicate_findings(new_run_findings)

      expect(result).to eq({
        "new123" => { path: "path/to/file3.rb", line: 30, message: "New finding 1", check_id: "RULE3" },
        "new456" => { path: "path/to/file4.rb", line: 40, message: "New finding 2", check_id: "RULE4" }
      })
    end

    it 'returns all findings if no comments from the bot exist' do
      allow(processor).to receive(:get_existing_comments).and_return([])

      result = processor.filter_duplicate_findings(new_run_findings)
      expect(result).to eq(new_run_findings)
    end

    it 'returns an empty hash if all fingerprints are already in bot comments' do
      allow(processor).to receive(:get_existing_comments).and_return([
        { "body" => "<!-- {\"fingerprint\":\"abc123\"} --> Some comment", "author" => { "id" => 123 } },
        { "body" => "<!-- {\"fingerprint\":\"def456\"} --> Another comment", "author" => { "id" => 123 } },
        { "body" => "<!-- {\"fingerprint\":\"new123\"} --> Yet another comment", "author" => { "id" => 123 } },
        { "body" => "<!-- {\"fingerprint\":\"new456\"} --> Another existing comment", "author" => { "id" => 123 } }
      ])

      result = processor.filter_duplicate_findings(new_run_findings)

      expect(result).to eq({})
    end

    it 'filters out findings with check_ids that are in the UNIQUE_COMMENT_RULES_IDS list' do
      new_run_findings["new789"] =
        { path: "path/to/file4.rb", line: 40, message: "New finding 2", check_id: first_unique_rule_id }
      new_run_findings["new890"] =
        { path: "path/to/file4.rb", line: 40, message: "New finding 2", check_id: first_unique_rule_id }
      result = processor.filter_duplicate_findings(new_run_findings)

      expect(result).to eq({
        "new123" => { path: "path/to/file3.rb", line: 30, message: "New finding 1",
                      check_id: "RULE3" },
        "new456" => { path: "path/to/file4.rb", line: 40, message: "New finding 2",
                      check_id: "RULE4" },
        "new789" => { path: "path/to/file4.rb", line: 40, message: "New finding 2",
                      check_id: first_unique_rule_id }
      })
    end
  end

  describe '#get_sast_results' do
    let(:sample_non_versioned_fingerprint) { "a5adf24a2512f31141f460e0bc18f39c8388105e564f" }
    let(:sample_message) { "This is a sample SAST finding message" }
    let(:scanned_path) { "ee/lib/ai/context/dependencies/config_files/python_pip.rb" }
    let(:check_id) { "builds.sast-custom-rules.secure-coding-guidelines.ruby.glappsec_insecure-regex" }
    let(:sample_data) do
      {
        "errors" => [],
        "interfile_languages_used" => [],
        "paths" => {
          "scanned" => [scanned_path],
          "skipped" => [
            { "path" => "ee/spec/lib/ai/context/dependencies/config_files/python_pip_spec.rb",
              "reason" => "cli_exclude_flags_match" },
            { "path" => "ee/spec/services/ai/repository_xray/scan_dependencies_service_spec.rb",
              "reason" => "cli_include_flags_do_not_match" }
          ]
        },
        "results" => [
          {
            "check_id" => check_id,
            "path" => scanned_path,
            "start" => { "line" => 9, "col" => 11, "offset" => 178 },
            "end" => { "line" => 9, "col" => 93, "offset" => 260 },
            "extra" => {
              "fingerprint" => "#{sample_non_versioned_fingerprint}_0",
              "message" => sample_message
            }
          },
          {
            "check_id" => check_id,
            "path" => scanned_path,
            "start" => { "line" => 9, "col" => 32, "offset" => 199 },
            "end" => { "line" => 9, "col" => 93, "offset" => 260 },
            "extra" => {
              "fingerprint" => "#{sample_non_versioned_fingerprint}_1",
              "message" => sample_message
            }
          }
        ],
        "skipped_rules" => [],
        "version" => "1.93.0"
      }
    end

    before do
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(report_file).and_return(JSON.generate(sample_data)) # rubocop:disable Gitlab/Json -- Used only in CI scripts
    end

    it 'parses the SAST report and prints findings correctly' do
      expected_output = {
        sample_non_versioned_fingerprint => {
          check_id: "builds.sast-custom-rules.secure-coding-guidelines.ruby.glappsec_insecure-regex",
          path: "ee/lib/ai/context/dependencies/config_files/python_pip.rb",
          line: 9,
          message: sample_message
        }
      }
      result = processor.get_sast_results

      expect(result).to eq(expected_output)
    end

    it 'prints findings to the console' do
      expect do
        processor.get_sast_results
      end.to output(
        %r{Finding \(Fingerprint: #{sample_non_versioned_fingerprint}\) in #{scanned_path} at line 9: #{sample_message}}
      ).to_stdout
    end

    it 'exits when no findings are present' do
      empty_data = sample_data.merge("results" => [])
      allow(File).to receive(:read).with(report_file).and_return(JSON.generate(empty_data)) # rubocop:disable Gitlab/Json -- Used only in CI scripts

      expect { processor.get_sast_results }.to raise_error(SystemExit).and output(/No findings./).to_stdout
    end

    context 'when check_id is absent from SAST results' do
      let(:check_id) { nil }

      it 'returns an empty check_id' do
        expected_output = {
          sample_non_versioned_fingerprint => {
            check_id: check_id,
            path: "ee/lib/ai/context/dependencies/config_files/python_pip.rb",
            line: 9,
            message: sample_message
          }
        }
        result = processor.get_sast_results
        expect(result).to eq(expected_output)
      end
    end
  end

  describe '#create_inline_comments' do
    around do |example|
      example.run
    rescue SystemExit
    end

    let(:path_line_message_dict) do
      {
        'fingerprint1' => { line: 10, message: 'Error message 1', path: 'file1.rb' },
        'fingerprint2' => { line: 20, message: 'Error message 2', path: 'file2.rb' }
      }
    end

    before do
      stub_env('CI_API_V4_URL', 'https://gitlab.example.com/api/v4')
      stub_env('CI_MERGE_REQUEST_PROJECT_ID', '123')
      stub_env('CI_MERGE_REQUEST_IID', '1')
      stub_env('CUSTOM_SAST_RULES_BOT_PAT', 'fake-token')

      allow(processor).to receive(:populate_commits_from_versions).and_return(%w[dummy_base_sha dummy_head_sha
        dummy_start_sha])
    end

    it 'posts multiple inline comments successfully' do
      successful_response = instance_double(Net::HTTPCreated, code: '201', body: '')
      allow(Net::HTTP).to receive(:start).and_return(successful_response)

      expect { processor.create_inline_comments(path_line_message_dict) }
        .not_to output.to_stdout
    end

    it 'handles failed comment post and outputs an error' do
      failed_response = instance_double(Net::HTTPBadRequest, code: '400', body: 'Bad Request')
      http = instance_double(Net::HTTP)

      allow(Net::HTTP).to receive(:start).and_yield(http)
      allow(http).to receive(:request).and_return(failed_response)
      allow(processor).to receive(:post_comment)

      expect(http).to receive(:request).twice
      expect { processor.create_inline_comments(path_line_message_dict) }
        .to output(/Failed to post inline comment with status code 400: Bad Request\. Posting normal comment instead\./)
              .to_stdout
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
