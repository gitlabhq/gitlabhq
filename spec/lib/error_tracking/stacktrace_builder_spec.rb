# frozen_string_literal: true

require 'fast_spec_helper'
require 'support/helpers/fast_rails_root'
require 'oj'

RSpec.describe ErrorTracking::StacktraceBuilder do
  include FastRailsRoot

  describe '#stacktrace' do
    let(:original_payload) { Gitlab::Json.parse(File.read(rails_root_join('spec/fixtures', payload_file))) }
    let(:payload) { original_payload }
    let(:payload_file) { 'error_tracking/parsed_event.json' }

    subject(:stacktrace) { described_class.new(payload).stacktrace }

    context 'with full error context' do
      it 'generates a correct stacktrace in expected format' do
        expected_context = [
          [132, "          end\n"],
          [133, "\n"],
          [134, "          begin\n"],
          [135, "            block.call(work, *extra)\n"],
          [136, "          rescue Exception => e\n"],
          [137, "            STDERR.puts \"Error reached top of thread-pool: #\{e.message\} (#\{e.class\})\"\n"],
          [138, "          end\n"]
        ]

        expected_entry = {
          'lineNo' => 135,
          'context' => expected_context,
          'filename' => 'puma/thread_pool.rb',
          'function' => 'block in spawn_thread',
          'colNo' => 0,
          'abs_path' =>
            "/Users/developer/.asdf/installs/ruby/2.5.1/lib/ruby/gems/2.5.0/gems/puma-3.12.6/lib/puma/thread_pool.rb"
        }

        expect(stacktrace).to be_kind_of(Array)
        expect(stacktrace.first).to eq(expected_entry)
      end
    end

    context 'when error context is missing' do
      let(:payload_file) { 'error_tracking/browser_event.json' }

      it 'generates a stacktrace without context' do
        expected_entry = {
          'lineNo' => 6395,
          'context' => [],
          'filename' => 'webpack-internal:///./node_modules/vue/dist/vue.runtime.esm.js',
          'function' => 'hydrate',
          'colNo' => 0,
          'abs_path' => nil
        }

        expect(stacktrace).to be_kind_of(Array)
        expect(stacktrace.first).to eq(expected_entry)
      end
    end

    context 'when exception payload is a list' do
      let(:payload_file) { 'error_tracking/go_two_exception_event.json' }

      it 'extracts a stracktrace' do
        expected_entry = {
          'lineNo' => 54,
          'context' => [
            [49, "\t// Set the timeout to the maximum duration the program can afford to wait."],
            [50, "\tdefer sentry.Flush(2 * time.Second)"],
            [51, ""],
            [52, "\tresp, err := http.Get(os.Args[1])"],
            [53, "\tif err != nil {"],
            [54, "\t\tsentry.CaptureException(err)"],
            [55, "\t\tlog.Printf(\"reported to Sentry: %s\", err)"],
            [56, "\t\treturn"],
            [57, "\t}"],
            [58, "\tdefer resp.Body.Close()"],
            [59, ""]
          ],
          'filename' => nil,
          'function' => 'main',
          'colNo' => 0,
          'abs_path' =>
            "/Users/stanhu/github/sentry-go/example/basic/main.go"
        }

        expect(stacktrace).to be_kind_of(Array)
        expect(stacktrace.first).to eq(expected_entry)
      end
    end

    context 'when stacktrace is in threads' do
      let(:payload_file) { 'error_tracking/dotnet_event.json' }

      it 'generates a correct stacktrace in expected format from threads' do
        expected_entry = {
          'lineNo' => 31,
          'context' => [],
          'filename' => 'Program.cs',
          'function' => 'void Program.<Main>$(?)',
          'colNo' => 0,
          'abs_path' =>
            "/Users/dev/work/dotnet-serilog-gitlab-sentry-bug-reproducible-example/Program.cs"
        }

        expect(stacktrace).to be_kind_of(Array)
        expect(stacktrace.first).to eq(expected_entry)
      end
    end

    context 'with empty payload' do
      let(:payload) { {} }

      it { is_expected.to eq([]) }
    end

    context 'without exception field' do
      let(:payload) { original_payload.except('exception') }

      it { is_expected.to eq([]) }
    end

    context 'without exception.values field' do
      before do
        original_payload['exception'].delete('values')
      end

      it { is_expected.to eq([]) }
    end

    context 'without any exception.values[].stacktrace fields' do
      before do
        original_payload.dig('exception', 'values').each { |value| value['stacktrace'] = '' }
      end

      it { is_expected.to eq([]) }
    end

    context 'without any exception.values[].stacktrace.frame fields' do
      before do
        original_payload.dig('exception', 'values').each { |value| value['stacktrace'].delete('frames') }
      end

      it { is_expected.to eq([]) }
    end
  end
end
