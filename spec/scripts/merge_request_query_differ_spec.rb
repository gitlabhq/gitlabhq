# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../scripts/merge_request_query_differ'

RSpec.describe MergeRequestQueryDiffer, feature_category: :tooling do
  let(:logger) { instance_double(Logger) }
  let(:sql_fingerprint_extractor) { instance_double(SQLFingerprintExtractor) }

  let(:file_content) do
    %(
      {"fingerprint":"def456","normalized":"SELECT * FROM projects WHERE user_id = $1"}
      {"normalized":"SELECT * FROM issues"}
      invalid json line,
      {"fingerprint":"abc123","normalized":"SELECT * FROM users WHERE id = $1"}
    )
  end

  let(:empty_file) { Tempfile.new(%w[mr_auto_explain.ndjson]) }
  let(:temp_file) { Tempfile.new(%w[mr_auto_explain.ndjson]) }

  before do
    allow(Logger).to receive(:new).and_return(logger)
    allow(SQLFingerprintExtractor).to receive(:new).and_return(sql_fingerprint_extractor)
    allow(logger).to receive_messages(info: nil, warn: nil, error: nil)
    allow(differ).to receive(:write_report)
  end

  subject(:differ) { described_class.new(empty_file.path, logger) }

  describe "#run" do
    context "when no queries are found in MR" do
      it "exits early and writes an appropriate report" do
        allow(sql_fingerprint_extractor).to receive(:extract_queries_from_file).and_return([])

        result = differ.run

        expect(result).to eq(0)
        expect(differ).to have_received(:write_report).with(
          differ.output_file,
          "# SQL Query Analysis\n\nNo queries found in this MR."
        )
      end
    end

    context "when queries without fingerprints are found in MR" do
      it "exits early without further processing" do
        allow(differ).to receive(:get_master_fingerprints)
        allow(sql_fingerprint_extractor).to receive(:extract_queries_from_file)
          .and_return([{ 'normalized' => 'SELECT * FROM issues' }])

        result = differ.run

        expect(differ).not_to have_received(:get_master_fingerprints)
        expect(result).to eq(0)
      end
    end

    context "when no master fingerprints are found" do
      it "exits early without comparing queries" do
        allow(sql_fingerprint_extractor).to receive(:extract_queries_from_file)
          .and_return([{ 'fingerprint' => 'fp1', 'normalized' => 'SELECT * FROM users' }])
        allow(differ).to receive(:get_master_fingerprints).and_return(Set.new)
        allow(differ).to receive(:filter_new_queries)

        result = differ.run

        expect(differ).not_to have_received(:filter_new_queries)
        expect(result).to eq(0)
      end
    end

    context "when everything works as expected" do
      it "processes the entire pipeline from extraction to report generation" do
        allow(sql_fingerprint_extractor).to receive(:extract_queries_from_file)
          .and_return([
            { 'fingerprint' => 'fp3', 'normalized' => 'SELECT * FROM issues' },
            { 'fingerprint' => 'fp1', 'normalized' => 'SELECT * FROM users' },
            { 'fingerprint' => 'fp2', 'normalized' => 'SELECT * FROM projects' }
          ])
        allow(differ).to receive(:get_master_fingerprints).and_return(Set.new(['fp1']))
        allow(differ.report_generator).to receive(:generate).and_return("# Sample Test Report")

        result = differ.run

        expect(differ).to have_received(:write_report).with(differ.output_file, "# Sample Test Report")
        expect(result).to eq(2) # Two new queries (fp2 and fp3)
      end
    end

    context "when errors occur" do
      it "handles errors gracefully" do
        allow(sql_fingerprint_extractor).to receive(:extract_queries_from_file)
          .and_raise(StandardError.new("Test error"))

        result = differ.run

        expect(differ).to have_received(:write_report).with(
          differ.output_file,
          "# SQL Query Analysis\n\n️ Analysis failed: Test error"
        )
        expect(result).to eq(0)
      end
    end
  end

  describe "#get_master_fingerprints" do
    it "downloads and extracts fingerprints from the consolidated package" do
      package_content = "mock_package_content"
      master_fingerprints = Set.new(%w[fd96528f933e7661 b10ab3c1b7bf923e b65a3b193bb3d1fb])

      allow(differ).to receive(:download_consolidated_package).and_return(package_content)
      allow(sql_fingerprint_extractor).to receive(:extract_from_tar_gz)
        .with(package_content)
        .and_return(master_fingerprints)

      result = differ.get_master_fingerprints

      expect(result).to be_a(Set)
      expect(result.size).to eq(3)
      expect(result).to eq(master_fingerprints)
    end

    it "handles download failures" do
      allow(differ).to receive(:download_consolidated_package).and_return(nil)

      result = differ.get_master_fingerprints

      expect(result).to be_a(Set)
      expect(result).to be_empty
      expect(logger).to have_received(:error).with("Failed to download consolidated package")
    end

    it "handles extraction errors" do
      allow(differ).to receive(:download_consolidated_package).and_return("package_content")
      allow(sql_fingerprint_extractor).to receive(:extract_from_tar_gz)
        .and_raise(StandardError.new("Extraction error"))

      result = differ.get_master_fingerprints

      expect(result).to be_a(Set)
      expect(result).to be_empty
      expect(logger).to have_received(:error).with("Error loading master fingerprints: Extraction error")
    end
  end

  describe "#filter_new_queries" do
    let(:mr_queries) do
      [
        { 'fingerprint' => 'fp3', 'normalized' => 'SELECT * FROM issues' },
        { 'fingerprint' => 'fp1', 'normalized' => 'SELECT * FROM users' },
        { 'fingerprint' => 'fp2', 'normalized' => 'SELECT * FROM projects' }
      ]
    end

    it "identifies queries with fingerprints not present in master" do
      master_fingerprints = Set.new(['fp2'])
      result = differ.filter_new_queries(mr_queries, master_fingerprints)
      expect(result.pluck('fingerprint')).to contain_exactly('fp1', 'fp3')
    end

    it "filters out all queries when all fingerprints are in master" do
      master_fingerprints = Set.new(%w[fp2 fp1 fp3])
      result = differ.filter_new_queries(mr_queries, master_fingerprints)
      expect(result).to be_empty
    end

    it "writes a report when no new queries are found" do
      master_fingerprints = Set.new(%w[fp2 fp1 fp3])
      differ.filter_new_queries(mr_queries, master_fingerprints)
      expect(differ).to have_received(:write_report).with(differ.output_file, /No new SQL queries detected in this MR/)
    end
  end

  describe "#download_consolidated_package" do
    let(:url) { URI(MergeRequestQueryDiffer::CONSOLIDATED_FINGERPRINTS_URL) }
    let(:max_size_mb) { 10 }

    it "downloads the package when file size is acceptable" do
      head_response = instance_double(Net::HTTPSuccess, is_a?: true, :[] => "5242880") # 5MB
      package_content = "mock package content"

      allow(differ).to receive(:make_request).with(url, method: :head, parse_json: false).and_return(head_response)
      allow(differ).to receive(:make_request).with(url, method: :get, parse_json: false).and_return(package_content)

      result = differ.download_consolidated_package(max_size_mb)
      expect(result).to eq(package_content)
    end

    it "aborts download when file size is too large" do
      head_response = instance_double(Net::HTTPSuccess, is_a?: true, :[] => ((max_size_mb + 1) * (1024**2)).to_s) # 11MB

      allow(differ).to receive(:make_request).with(url, method: :head, parse_json: false).and_return(head_response)
      allow(differ).to receive(:make_request).with(url, method: :get, parse_json: false)

      result = differ.download_consolidated_package(max_size_mb)

      expect(differ).to have_received(:make_request).with(url, method: :head, parse_json: false)
      expect(differ).not_to have_received(:make_request).with(url, method: :get, parse_json: false)
      expect(result).to be_nil
    end

    it "proceeds with download when size check fails" do
      package_content = "mock package content"
      allow(differ).to receive(:make_request)
        .with(url, method: :head, parse_json: false)
        .and_raise(StandardError.new("Size check failed"))
      allow(differ).to receive(:make_request)
        .with(url, method: :get, parse_json: false)
        .and_return(package_content)

      result = differ.download_consolidated_package(max_size_mb)

      expect(result).to eq(package_content)
      expect(logger).to have_received(:warn).with(/Warning: Could not validate file size/)
      expect(differ).to have_received(:make_request).with(url, method: :get, parse_json: false)
    end
  end

  describe "#make_request" do
    let(:test_url) { URI("https://gitlab.example.com/foo/bar") }
    let(:http) { instance_double(Net::HTTP) }
    let(:request) { instance_double(Net::HTTP::Get) }
    let(:success_response) { Net::HTTPSuccess.new('1.1', '200', 'OK') }

    before do
      allow(Net::HTTP).to receive(:new).with(any_args).and_return(http)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:read_timeout=)
      allow(success_response).to receive(:body).and_return('{"data":"success"}')
      allow(http).to receive(:request).and_return(success_response)
    end

    context "with authentication headers" do
      before do
        allow(Net::HTTP::Get).to receive(:new).and_return(request)
        allow(request).to receive(:[]=)
      end

      it "set PRIVATE-TOKEN when GITLAB_TOKEN present" do
        stub_env('GITLAB_TOKEN', "test-gitlab-token")
        differ.make_request(test_url)
        expect(request).to have_received(:[]=).with('PRIVATE-TOKEN', "test-gitlab-token")
      end

      it "set JOB-TOKEN when CI_JOB_TOKEN present" do
        stub_env('CI_JOB_TOKEN', "test-ci-job-token")
        differ.make_request(test_url)
        expect(request).to have_received(:[]=).with('JOB-TOKEN', "test-ci-job-token")
      end

      it "prefers GITLAB_TOKEN over CI_JOB_TOKEN" do
        stub_env('CI_JOB_TOKEN', "test-ci-job-token")
        stub_env('GITLAB_TOKEN', "test-gitlab-token")

        differ.make_request(test_url)
        expect(request).to have_received(:[]=).with('PRIVATE-TOKEN', "test-gitlab-token")
        expect(request).not_to have_received(:[]=).with('JOB-TOKEN', "test-ci-job-token")
      end
    end

    it "stops retrying after max attempts" do
      result = differ.make_request(test_url, attempt: 4, max_attempts: 3)
      expect(result).to eq([])
      expect(logger).to have_received(:info).with("Maximum retry attempts (3) reached for rate limiting")
    end

    it "returns parsed JSON for successful requests" do
      result = differ.make_request(test_url)
      expect(result).to eq({ "data" => "success" })
    end

    it "returns raw response body when parse_json is false" do
      allow(success_response).to receive(:body).and_return('raw response data')
      result = differ.make_request(test_url, parse_json: false)
      expect(result).to eq('raw response data')
    end

    it "supports HEAD requests" do
      result = differ.make_request(test_url, method: :head, parse_json: false)
      expect(result).to eq(success_response)
    end

    context "when handling errors" do
      it "retries on common server errors" do
        allow(http).to receive(:request).and_return(
          Net::HTTPServiceUnavailable.new('1.1', '503', 'Service Unavailable'),
          Net::HTTPTooManyRequests.new('1.1', '429', 'Too Many Requests'),
          success_response
        )
        allow(differ).to receive(:sleep)

        result = differ.make_request(test_url)
        expect(result).to eq({ "data" => "success" })
      end

      it "returns empty json when parse_json is true" do
        allow(http).to receive(:request).and_return(Net::HTTPFatalError)
        expect(differ.make_request(test_url, method: :get, parse_json: true)).to eq([])
      end

      it "returns nil when parse json is false" do
        allow(http).to receive(:request).and_return(Net::HTTPFatalError)
        expect(differ.make_request(test_url, method: :get, parse_json: false)).to be_nil
      end

      it "logs error when resource not found" do
        allow(http).to receive(:request).and_return(Net::HTTPNotFound.new('1.1', '404', 'Test 404'))
        expect(differ.make_request(test_url, method: :get, parse_json: true)).to eq([])
        expect(logger).to have_received(:error).with(/HTTP request failed: 404 - Test 404/)
      end

      it "logs error if an unsupported method is passed" do
        result = differ.make_request(test_url, method: :put, parse_json: false)

        expect(result).to be_nil
        expect(logger).to have_received(:error).with(/Error making request: Unsupported HTTP method: put/)
      end

      it "returns nil and logs error when exception occurs" do
        allow(http).to receive(:request).and_raise(StandardError.new("Testing Error"))

        result = differ.make_request(test_url, parse_json: false)

        expect(result).to be_nil
        expect(logger).to have_received(:error).with("Error making request: Testing Error")
      end

      it "returns empty array and logs error when JSON parsing fails" do
        allow(success_response).to receive(:body).and_return('invalid json')
        result = differ.make_request(test_url)
        expect(result).to eq([])
        expect(logger).to have_received(:error).with(/Failed to parse JSON/)
      end
    end
  end

  describe "#write_report" do
    subject(:differ) { described_class.new(empty_file, logger) }

    before do
      allow(logger).to receive(:info)
      allow(differ).to receive(:write_report).and_call_original
      allow(File).to receive(:write)
    end

    it "writes content to file and logs success" do
      differ.write_report("test.txt", "content")
      expect(logger).to have_received(:info).with("Report saved to test.txt")
    end

    it "logs errors when file write fails" do
      allow(File).to receive(:write).and_raise(StandardError.new("Write error"))

      differ.write_report("test.txt", "content")
      expect(logger).to have_received(:error).with("Could not write report to file: Write error")
    end
  end

  describe "ReportGenerator" do
    let(:report_generator) { differ.report_generator }

    it "generates a report with new queries" do
      report = report_generator.generate([{ 'fingerprint' => 'fp1', 'normalized' => 'SELECT * FROM users' }])

      expect(report).to include("# SQL Query Analysis")
      expect(report).to include("Identified potential 1 new SQL queries")
      expect(report).to include("Query 1")
      expect(report).to include("SELECT * FROM users")
      expect(report).to include("fp1")
    end

    it "includes execution plans when available" do
      report = report_generator.generate([
        { 'fingerprint' => 'fp1', 'normalized' => 'SELECT * FROM users', 'plan' => { 'Node Type' => 'Index Scan' } }
      ])
      expect(report).to include("Execution Plan")
      expect(report).to include("Index Scan")
    end

    it "handles empty query list" do
      report = report_generator.generate([])
      expect(report).to include("No new SQL queries detected in this MR")
    end

    it "formats hash plan" do
      hash_plan = { 'Node Type' => 'Index Scan' }
      result = report_generator.format_plan(hash_plan)
      expect(result).to include('  "Node Type": "Index Scan"')
    end

    it "formats non hash plan" do
      result = report_generator.format_plan(1234)
      expect(result).to include('1234')
    end
  end
end
