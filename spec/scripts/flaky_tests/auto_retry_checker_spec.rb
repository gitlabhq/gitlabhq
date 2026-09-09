# frozen_string_literal: true

require 'fast_spec_helper'
require 'fileutils'
require_relative '../../../scripts/flaky_tests/auto_retry_checker'

RSpec.describe AutoRetryChecker, feature_category: :tooling do
  let(:last_run_results_path) { Tempfile.new('rspec_last_run').path }
  let(:flaky_test_list_url) { 'https://example.com/flaky-tests.json' }
  let(:checker) do
    described_class.new(last_run_results_path: last_run_results_path, flaky_test_list_url: flaky_test_list_url)
  end

  let(:flaky_spec) { 'spec/models/user_spec.rb' }
  let(:clean_spec) { 'spec/models/project_spec.rb' }

  let(:master_only_flaky_spec) { 'spec/models/admin_spec.rb' }

  let(:flaky_list_response) do
    "[{\"file_path\":\"#{flaky_spec}\",\"master_only_flaky\":false}," \
      "{\"file_path\":\"#{master_only_flaky_spec}\",\"master_only_flaky\":true}," \
      "{\"file_path\":\"spec/other_spec.rb\",\"master_only_flaky\":false}]"
  end

  before do
    allow(checker).to receive(:fetch_url).and_return(flaky_list_response)
  end

  after do
    FileUtils.rm_f(last_run_results_path)
  end

  def write_results(lines)
    File.write(last_run_results_path, lines.join("\n"))
  end

  describe '#run' do
    context 'when a failed spec file is in the flaky list' do
      before do
        write_results(["./#{flaky_spec}[1:1] failed", "./#{clean_spec}[1:2] passed"])
      end

      it 'exits with code 112' do
        expect { checker.run }.to raise_error(SystemExit) do |e|
          expect(e.status).to eq(described_class::EXIT_CODE_KNOWN_FLAKY)
        end
      end
    end

    context 'when no failed spec file is in the flaky list' do
      before do
        write_results(["./#{clean_spec}[1:2] failed"])
      end

      it 'returns without exiting' do
        expect { checker.run }.not_to raise_error
      end
    end

    context 'when the flaky spec passed on retry (only non-failed lines remain)' do
      before do
        write_results(["./#{flaky_spec}[1:1] passed"])
      end

      it 'does not trigger a retry' do
        expect { checker.run }.not_to raise_error
      end
    end

    context 'when the last run results file does not exist' do
      let(:last_run_results_path) { '/nonexistent/path.txt' }

      it 'returns without exiting' do
        expect { checker.run }.not_to raise_error
      end
    end

    context 'when the flaky list fetch fails' do
      before do
        allow(checker).to receive(:fetch_url).and_return(nil)
        write_results(["./#{flaky_spec}[1:1] failed"])
      end

      it 'fails open and returns without exiting' do
        expect { checker.run }.not_to raise_error
      end
    end

    context 'when the flaky list response is invalid JSON' do
      before do
        allow(checker).to receive(:fetch_url).and_return('not json')
        write_results(["./#{flaky_spec}[1:1] failed"])
      end

      it 'fails open and returns without exiting' do
        expect { checker.run }.not_to raise_error
      end
    end

    context 'when the last run results file is empty' do
      before do
        write_results([])
      end

      it 'returns without exiting' do
        expect { checker.run }.not_to raise_error
      end
    end

    context 'when the failing spec is master_only_flaky and running in an MR pipeline' do
      before do
        stub_env('CI_MERGE_REQUEST_IID', '123')
        write_results(["./#{master_only_flaky_spec}[1:1] failed"])
      end

      it 'does not trigger a retry' do
        expect { checker.run }.not_to raise_error
      end
    end

    context 'when the failing spec is master_only_flaky but running on the default branch' do
      before do
        stub_env('CI_MERGE_REQUEST_IID', nil)
        write_results(["./#{master_only_flaky_spec}[1:1] failed"])
      end

      it 'exits with code 112' do
        expect { checker.run }.to raise_error(SystemExit) do |e|
          expect(e.status).to eq(described_class::EXIT_CODE_KNOWN_FLAKY)
        end
      end
    end

    context 'when GLCI_FLAKY_TEST_LIST_URL is not set' do
      let(:checker) { described_class.new(last_run_results_path: last_run_results_path, flaky_test_list_url: nil) }

      before do
        write_results(["./#{flaky_spec}[1:1] failed"])
      end

      it 'skips the check and returns without exiting' do
        expect(checker).not_to receive(:fetch_url)
        expect { checker.run }.not_to raise_error
      end
    end
  end

  describe '#fetch_url' do
    # Use a fresh checker without the fetch_url stub from the outer before block.
    let(:real_checker) do
      described_class.new(last_run_results_path: last_run_results_path, flaky_test_list_url: flaky_test_list_url)
    end

    subject(:fetch) { real_checker.send(:fetch_url, flaky_test_list_url) }

    def make_response(klass, code, body: nil, location: nil)
      response = klass.new('1.1', code, klass.name)
      allow(response).to receive(:body).and_return(body) if body
      allow(response).to receive(:[]).with('location').and_return(location) if location
      response
    end

    context 'when the request succeeds' do
      before do
        allow(Net::HTTP).to receive(:start).and_return(make_response(Net::HTTPOK, '200', body: '[]'))
      end

      it 'returns the response body' do
        expect(fetch).to eq('[]')
      end
    end

    context 'when the server returns a redirect' do
      let(:redirect_url) { 'https://example.com/redirected.json' }

      before do
        allow(Net::HTTP).to receive(:start).and_return(
          make_response(Net::HTTPMovedPermanently, '301', location: redirect_url)
        )
        allow(real_checker).to receive(:fetch_url).with(redirect_url, redirect_limit: anything).and_return('[]')
        allow(real_checker).to receive(:fetch_url).with(flaky_test_list_url).and_call_original
      end

      it 'follows the redirect and returns the body' do
        expect(fetch).to eq('[]')
      end
    end

    context 'when the server returns an error' do
      before do
        allow(Net::HTTP).to receive(:start).and_return(make_response(Net::HTTPInternalServerError, '500'))
      end

      it 'returns nil' do
        expect(fetch).to be_nil
      end
    end

    context 'when a network error occurs' do
      before do
        allow(Net::HTTP).to receive(:start).and_raise(SocketError, 'failed to connect')
      end

      it 'returns nil' do
        expect(fetch).to be_nil
      end
    end
  end
end
