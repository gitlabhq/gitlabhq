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

    shared_examples 'does not comment on MR with stop labels' do
      it "returns early and does not comment" do
        expect(processor).to receive(:perform_allowlist_check)
        expect(processor).to receive(:get_sast_results)
        expect(processor).to receive(:filter_duplicate_findings).with(sample_results)

        expect do
          processor.execute
        end.to output(%r{Not adding comments for this MR as it has the appsec-sast::stop / pipeline::tier-3 label})
                 .to_stdout

        expect(processor).not_to receive(:create_inline_comments)
      end
    end

    context 'when CI_MERGE_REQUEST_LABELS includes appsec-sast::stop' do
      before do
        stub_env('CI_MERGE_REQUEST_LABELS', 'appsec-sast::stop')
      end

      it_behaves_like 'does not comment on MR with stop labels'
    end

    context 'when CI_MERGE_REQUEST_LABELS includes pipeline::tier-3' do
      before do
        stub_env('CI_MERGE_REQUEST_LABELS', 'pipeline::tier-3')
      end

      it_behaves_like 'does not comment on MR with stop labels'
    end
  end

  describe '#sast_stop_label_present?' do
    context 'when CI_MERGE_REQUEST_LABELS includes appsec-sast::stop' do
      it 'returns true' do
        stub_env('CI_MERGE_REQUEST_LABELS', 'appsec-sast::stop, other-label')
        expect(processor.send(:sast_stop_label_present?)).to be true
      end
    end

    context 'when CI_MERGE_REQUEST_LABELS does not include appsec-sast::stop' do
      it 'returns false' do
        stub_env('CI_MERGE_REQUEST_LABELS', 'another-label, different-label')
        expect(processor.send(:sast_stop_label_present?)).to be false
      end
    end

    context 'when CI_MERGE_REQUEST_LABELS is empty' do
      it 'returns false' do
        stub_env('CI_MERGE_REQUEST_LABELS', '')
        expect(processor.send(:sast_stop_label_present?)).to be false
      end
    end

    context 'when CI_MERGE_REQUEST_LABELS is nil' do
      it 'returns false' do
        stub_env('CI_MERGE_REQUEST_LABELS', nil)
        expect(processor.send(:sast_stop_label_present?)).to be false
      end
    end
  end

  describe '#pipeline_tier_three_label_present?' do
    context 'when CI_MERGE_REQUEST_LABELS includes pipeline::tier-3' do
      it 'returns true' do
        stub_env('CI_MERGE_REQUEST_LABELS', 'pipeline::tier-3, other-label')
        expect(processor.send(:pipeline_tier_three_label_present?)).to be true
      end
    end

    context 'when CI_MERGE_REQUEST_LABELS does not include pipeline::tier-3' do
      it 'returns false' do
        stub_env('CI_MERGE_REQUEST_LABELS', 'another-label, different-label')
        expect(processor.send(:pipeline_tier_three_label_present?)).to be false
      end
    end

    context 'when CI_MERGE_REQUEST_LABELS is empty' do
      it 'returns false' do
        stub_env('CI_MERGE_REQUEST_LABELS', '')
        expect(processor.send(:pipeline_tier_three_label_present?)).to be false
      end
    end

    context 'when CI_MERGE_REQUEST_LABELS is nil' do
      it 'returns false' do
        stub_env('CI_MERGE_REQUEST_LABELS', nil)
        expect(processor.send(:pipeline_tier_three_label_present?)).to be false
      end
    end
  end

  describe '#apply_label' do
    it 'returns' do
      successful_response = instance_double(Net::HTTPOK, code: '200', body: 'Successful response')
      http = instance_double(Net::HTTP)

      allow(Net::HTTP).to receive(:start).and_yield(http)
      allow(http).to receive(:request).and_return(successful_response)

      expect(processor.send(:apply_label)).to be_nil
    end

    it 'handles error response' do
      failed_response = instance_double(Net::HTTPBadRequest, code: '400', body: 'Bad Request')
      http = instance_double(Net::HTTP)

      allow(Net::HTTP).to receive(:start).and_yield(http)
      allow(http).to receive(:request).and_return(failed_response)
      allow(processor).to receive(:post_comment)

      expect do
        processor.send(:apply_label)
      end.to output(%r{Failed to apply labels with status code 400: Bad Request})
               .to_stdout
    end
  end

  describe SemgrepResultProcessor do
    describe '#perform_allowlist_check' do
      let(:processor) { described_class.new }
      let(:original_env) { ENV.to_hash }

      after do
        # Restore original environment after each test
        ENV.clear
        original_env.each { |k, v| stub_env(k, v) }
      end

      context 'when CI_PROJECT_DIR is not allowlisted' do
        before do
          stub_env('CI_PROJECT_DIR', '/tmp/not_allowlisted')
          # Set a valid API URL to isolate the test to just the project dir check
          stub_env('CI_API_V4_URL', 'https://gitlab.com/api/v4')
        end

        it 'exits with status code 1' do
          expect { processor.perform_allowlist_check }.to raise_error(SystemExit) do |error|
            expect(error.status).to eq(1)
          end
        end

        it 'outputs an error message' do
          expect do
            processor.perform_allowlist_check
          rescue SystemExit
            # Catch the exit to continue the test
          end.to output(%r{Error: CI_PROJECT_DIR '/tmp/not_allowlisted' is not allowed.}).to_stdout
        end
      end

      context 'when CI_PROJECT_DIR is allowlisted but CI_API_V4_URL is not' do
        before do
          # Set an allowed project dir
          stub_env('CI_PROJECT_DIR', '/builds/gitlab-org/gitlab')
          # Set a non-allowed API URL
          stub_env('CI_API_V4_URL', 'https://not-allowed-api.com')
        end

        it 'exits with status code 1' do
          expect { processor.perform_allowlist_check }.to raise_error(SystemExit) do |error|
            expect(error.status).to eq(1)
          end
        end

        it 'outputs an error message about the API URL' do
          expect do
            processor.perform_allowlist_check
          rescue SystemExit
            # Catch the exit to continue the test
          end.to output(%r{Error: CI_API_V4_URL 'https://not-allowed-api.com' is not allowed.}).to_stdout
        end
      end

      context 'when both CI_PROJECT_DIR and CI_API_V4_URL are allowlisted' do
        before do
          stub_env('CI_PROJECT_DIR', '/builds/gitlab-org/gitlab')
          stub_env('CI_API_V4_URL', 'https://gitlab.com/api/v4')
        end

        it 'completes successfully without exiting' do
          expect { processor.perform_allowlist_check }.not_to raise_error
        end
      end
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
    let(:processor) { described_class.new }
    let(:base_sha) { 'base_sha' }
    let(:head_sha) { 'head_sha' }
    let(:start_sha) { 'start_sha' }

    before do
      stub_env('CI_API_V4_URL', 'https://gitlab.example.com/api/v4')
      stub_env('CI_MERGE_REQUEST_PROJECT_ID', '123')
      stub_env('CI_MERGE_REQUEST_IID', '1')
      stub_env('CUSTOM_SAST_RULES_BOT_PAT', 'fake-token')
      allow(processor).to receive(:populate_commits_from_versions).and_return([base_sha, head_sha, start_sha])
      # More robust mocking of HTTP operations
      allow(processor).to receive(:post_comment)
    end

    context 'with secure coding guidelines finding' do
      let(:scg_finding) do
        {
          'fingerprint1' => {
            path: 'file1.rb',
            line: 10,
            message: 'Error message 1',
            check_id: 'builds.sast-custom-rules.secure-coding-guidelines.ruby'
          }
        }
      end

      it 'posts comment with SCG suffix and applies label' do
        # Create a successful HTTP response mock
        successful_response = instance_double(Net::HTTPCreated)
        allow(successful_response).to receive(:instance_of?).with(Net::HTTPCreated).and_return(true)
        allow(successful_response).to receive_messages(code: '201', body: 'Success')

        # Mock Net::HTTP to capture and validate what happens with our mocked services
        http_double = instance_double(Net::HTTP)
        allow(http_double).to receive(:request).and_return(successful_response)
        allow(Net::HTTP).to receive(:start).and_yield(http_double)

        # Expect apply_label to be called
        expect(processor).to receive(:apply_label).once

        # Expect post_comment not to be called
        expect(processor).not_to receive(:post_comment)

        # Run the method
        processor.create_inline_comments(scg_finding)
      end
    end

    context 'with s1 finding' do
      let(:s1_finding) do
        {
          'fingerprint2' => {
            path: 'file2.rb',
            line: 20,
            message: 'Error message 2',
            check_id: 'builds.sast-custom-rules.s1.rule'
          }
        }
      end

      it 'posts comment with S1 suffix and applies label' do
        # Create a successful HTTP response mock
        successful_response = instance_double(Net::HTTPCreated)
        allow(successful_response).to receive(:instance_of?).with(Net::HTTPCreated).and_return(true)
        allow(successful_response).to receive_messages(code: '201', body: 'Success')

        # Track the form data being sent
        form_data_captured = nil

        # Create a request double that can capture form data
        request_double = instance_double(Net::HTTP::Post)
        allow(request_double).to receive(:[]=)
        allow(request_double).to receive(:set_form_data) do |data|
          form_data_captured = data
        end

        # Mock Net::HTTP::Post.new to return our request double
        allow(Net::HTTP::Post).to receive(:new).and_return(request_double)

        # Mock HTTP to return successful response
        http_double = instance_double(Net::HTTP)
        allow(http_double).to receive(:request).and_return(successful_response)
        allow(Net::HTTP).to receive(:start).and_yield(http_double)

        # Expect apply_label to be called
        expect(processor).to receive(:apply_label).once

        # Run the method
        processor.create_inline_comments(s1_finding)

        # Verify the message includes the S1 ping
        expect(form_data_captured["body"]).to include(described_class::MESSAGE_S1_PING_APPSEC)
      end
    end

    context 'with other finding type' do
      let(:other_finding) do
        {
          'fingerprint3' => {
            path: 'file3.rb',
            line: 30,
            message: 'Error message 3',
            check_id: 'builds.sast-custom-rules.other'
          }
        }
      end

      it 'posts comment with default suffix and applies label' do
        # Create a successful HTTP response mock
        successful_response = instance_double(Net::HTTPCreated)
        allow(successful_response).to receive(:instance_of?).with(Net::HTTPCreated).and_return(true)
        allow(successful_response).to receive_messages(code: '201', body: 'Success')

        # Track the form data being sent
        form_data_captured = nil

        # Create a request double that can capture form data
        request_double = instance_double(Net::HTTP::Post)
        allow(request_double).to receive(:[]=)
        allow(request_double).to receive(:set_form_data) do |data|
          form_data_captured = data
        end

        # Mock Net::HTTP::Post.new to return our request double
        allow(Net::HTTP::Post).to receive(:new).and_return(request_double)

        # Mock HTTP to return successful response
        http_double = instance_double(Net::HTTP)
        allow(http_double).to receive(:request).and_return(successful_response)
        allow(Net::HTTP).to receive(:start).and_yield(http_double)

        # Expect apply_label to be called
        expect(processor).to receive(:apply_label).once

        # Run the method
        processor.create_inline_comments(other_finding)

        # Manually verify the message - there's an issue with the code that needs fixing
        # This test will fail until that's addressed - the "" in the else clause is causing issues
        message_without_newlines = form_data_captured["body"].delete("\n")
        expect(message_without_newlines).to include(described_class::MESSAGE_PING_APPSEC.delete("\n"))
      end
    end

    context 'with failed HTTP response' do
      let(:finding) do
        {
          'fingerprint4' => {
            path: 'file4.rb',
            line: 40,
            message: 'Error message 4',
            check_id: 'some.rule'
          }
        }
      end

      it 'falls back to post_comment when inline comment fails' do
        # Create a failed HTTP response mock
        failed_response = instance_double(Net::HTTPBadRequest)
        allow(failed_response).to receive(:instance_of?).with(Net::HTTPCreated).and_return(false)
        allow(failed_response).to receive_messages(code: '400', body: 'Bad Request')

        # Mock request
        request_double = instance_double(Net::HTTP::Post)
        allow(request_double).to receive(:[]=)
        allow(request_double).to receive(:set_form_data)
        allow(Net::HTTP::Post).to receive(:new).and_return(request_double)

        # Mock HTTP to return failed response
        http_double = instance_double(Net::HTTP)
        allow(http_double).to receive(:request).and_return(failed_response)
        allow(Net::HTTP).to receive(:start).and_yield(http_double)

        # Expect post_comment to be called
        expect(processor).to receive(:post_comment).once

        # Output should include error message
        expect do
          processor.create_inline_comments(finding)
        end.to output(/Failed to post inline comment with status code 400/).to_stdout
      end
    end

    context 'with multiple findings' do
      let(:mixed_findings) do
        {
          'fingerprint1' => {
            path: 'file1.rb',
            line: 10,
            message: 'Error message 1',
            check_id: 'builds.sast-custom-rules.secure-coding-guidelines.ruby'
          },
          'fingerprint2' => {
            path: 'file2.rb',
            line: 20,
            message: 'Error message 2',
            check_id: 'builds.sast-custom-rules.s1.rule'
          }
        }
      end

      it 'processes all findings correctly' do
        # Create response doubles
        successful_response = instance_double(Net::HTTPCreated)
        allow(successful_response).to receive(:instance_of?).with(Net::HTTPCreated).and_return(true)
        allow(successful_response).to receive_messages(code: '201', body: 'Success')

        failed_response = instance_double(Net::HTTPBadRequest)
        allow(failed_response).to receive(:instance_of?).with(Net::HTTPCreated).and_return(false)
        allow(failed_response).to receive_messages(code: '400', body: 'Bad Request')

        # Mock request
        request_double = instance_double(Net::HTTP::Post)
        allow(request_double).to receive(:[]=)
        allow(request_double).to receive(:set_form_data)
        allow(Net::HTTP::Post).to receive(:new).and_return(request_double)

        # Track call count to return different responses
        call_count = 0
        http_double = instance_double(Net::HTTP)
        allow(http_double).to receive(:request) do
          call_count += 1
          call_count == 1 ? successful_response : failed_response
        end
        allow(Net::HTTP).to receive(:start).and_yield(http_double)

        # Apply label should be called once
        expect(processor).to receive(:apply_label).once

        # Post_comment should be called once
        expect(processor).to receive(:post_comment).once

        # Run the method and check output
        expect do
          processor.create_inline_comments(mixed_findings)
        end.to output(/Failed to post inline comment with status code 400/).to_stdout
      end
    end
  end

  describe '#get_existing_comments' do
    before do
      stub_env('CI_API_V4_URL', 'https://gitlab.example.com/api/v4')
      stub_env('CI_MERGE_REQUEST_PROJECT_ID', '123')
      stub_env('CI_MERGE_REQUEST_IID', '1')
      stub_env('CUSTOM_SAST_RULES_BOT_PAT', 'fake-token')
    end

    around do |example|
      example.run
    rescue SystemExit
      # Catch SystemExit
    end

    context 'when API request is successful' do
      it 'returns parsed JSON response' do
        http_response = instance_double(Net::HTTPOK)
        allow(http_response).to receive(:instance_of?).with(Net::HTTPOK).and_return(true)
        allow(http_response).to receive(:body).and_return('[{"id": 1, "body": "Comment"}]')

        http_double = instance_double(Net::HTTP)
        allow(http_double).to receive(:request).and_return(http_response)
        allow(Net::HTTP).to receive(:start).and_yield(http_double)

        result = processor.send(:get_existing_comments)
        expect(result).to eq([{ "id" => 1, "body" => "Comment" }])
      end
    end

    context 'when API request fails' do
      it 'outputs error message, posts comment, and exits' do
        failed_response = instance_double(Net::HTTPBadRequest)
        allow(failed_response).to receive(:instance_of?).with(Net::HTTPOK).and_return(false)
        allow(failed_response).to receive_messages(code: '400', body: 'Bad Request')

        http_double = instance_double(Net::HTTP)
        allow(http_double).to receive(:request).and_return(failed_response)
        allow(Net::HTTP).to receive(:start).and_yield(http_double)

        # Expect post_comment to be called with specific message
        expect(processor).to receive(:post_comment).with(/Failed to fetch comments: Bad Request/)

        # Check for console output
        expect do
          # This will raise SystemExit which is caught by the around block
          processor.send(:get_existing_comments)
        end.to output(/Failed to fetch comments with status code 400/).to_stdout

        # Verify the exit code by capturing the raised exception
        begin
          processor.send(:get_existing_comments)
        rescue SystemExit => e
          expect(e.status).to eq(0)
        end
      end
    end
  end

  describe '#populate_commits_from_versions' do
    before do
      stub_env('CI_API_V4_URL', 'https://gitlab.example.com/api/v4')
      stub_env('CI_MERGE_REQUEST_PROJECT_ID', '123')
      stub_env('CI_MERGE_REQUEST_IID', '1')
      stub_env('CUSTOM_SAST_RULES_BOT_PAT', 'fake-token')
    end

    around do |example|
      example.run
    rescue SystemExit
      # Catch SystemExit
    end

    context 'when API request is successful' do
      it 'returns the three SHA values' do
        # Create mock response with sample data
        sample_response = [
          {
            'base_commit_sha' => 'abc123base',
            'head_commit_sha' => 'def456head',
            'start_commit_sha' => 'ghi789start'
          }
        ].to_json

        # Mock the HTTP response
        http_response = instance_double(Net::HTTPOK)
        allow(http_response).to receive(:instance_of?).with(Net::HTTPOK).and_return(true)
        allow(http_response).to receive(:body).and_return(sample_response)

        # Mock the HTTP request cycle
        http_double = instance_double(Net::HTTP)
        allow(http_double).to receive(:request).and_return(http_response)
        allow(Net::HTTP).to receive(:start).and_yield(http_double)

        # Call the method and verify the result
        result = processor.send(:populate_commits_from_versions)

        # Verify each SHA is correctly extracted and returned
        expect(result).to be_an(Array)
        expect(result.size).to eq(3)
        expect(result[0]).to eq('abc123base')   # base_sha
        expect(result[1]).to eq('def456head')   # head_sha
        expect(result[2]).to eq('ghi789start')  # start_sha
      end
    end

    context 'when API request fails' do
      it 'outputs error message, posts comment, and exits' do
        # Mock a failed HTTP response
        failed_response = instance_double(Net::HTTPBadRequest)
        allow(failed_response).to receive(:instance_of?).with(Net::HTTPOK).and_return(false)
        allow(failed_response).to receive_messages(code: '400', body: 'Bad Request')

        # Mock the HTTP request cycle
        http_double = instance_double(Net::HTTP)
        allow(http_double).to receive(:request).and_return(failed_response)
        allow(Net::HTTP).to receive(:start).and_yield(http_double)

        # Expect post_comment to be called with specific message
        expect(processor).to receive(:post_comment).with(/Failed to fetch versions: Bad Request/)

        # Check for console output
        expect do
          # This will raise SystemExit which is caught by the around block
          processor.send(:populate_commits_from_versions)
        end.to output(/Failed to fetch versions with status code 400/).to_stdout

        # Verify the exit code by capturing the raised exception
        begin
          processor.send(:populate_commits_from_versions)
        rescue SystemExit => e
          expect(e.status).to eq(0)
        end
      end
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
