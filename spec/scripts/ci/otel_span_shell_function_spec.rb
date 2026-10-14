# frozen_string_literal: true

require 'fast_spec_helper'
require 'open3'
require 'tmpdir'

RSpec.describe 'otel_span shell function', feature_category: :tooling do
  # The pilot job runs BusyBox sh (ruby:alpine has no Bash), so also test it where BusyBox is available.
  shells = { 'bash' => %w[bash] }
  busybox_available = ENV.fetch('PATH', '').split(File::PATH_SEPARATOR).any? do |dir|
    File.executable?(File.join(dir, 'busybox'))
  end
  shells['busybox sh'] = %w[busybox sh] if busybox_available

  let(:utils_path) { File.expand_path('../../../scripts/utils.sh', __dir__) }
  let(:tmp_dir) { Dir.mktmpdir }
  let(:exporter_log) { File.join(tmp_dir, 'exporter.log') }
  let(:fake_exporter) do
    File.join(tmp_dir, 'fake_exporter.rb').tap do |path|
      File.write(path, <<~RUBY)
        require '#{File.expand_path('../../../scripts/ci/otel_span_exporter', __dir__)}'
        if ARGV == ['--prepare-context']
          OtelSpanExporter.run(ARGV)
        else
          File.open(ENV.fetch('FAKE_EXPORTER_LOG'), 'a') { |f| f.puts(ARGV.join(' ')) }
        end
      RUBY
    end
  end

  let(:env) do
    {
      'GLCI_OTEL_ENDPOINT' => 'https://example.otel.gitlab-o11y.com:14318',
      'GLCI_OTEL_SPAN_EXPORTER' => fake_exporter,
      'FAKE_EXPORTER_LOG' => exporter_log,
      'CI_TRACEPARENT' => '00-000000000000000000000000acb87def-c929c65f80a6df0f-01',
      'CI_TRACESTATE' => 'gitlab=pipeline:2;job:3'
    }
  end

  after do
    FileUtils.rm_rf(tmp_dir)
  end

  def exported_spans
    return [] unless File.exist?(exporter_log)

    File.readlines(exporter_log, chomp: true).map do |line|
      line.scan(/--([a-z-]+) (\S+)/).to_h
    end
  end

  shells.each do |shell_name, shell_command|
    context "with #{shell_name}" do
      # Runs the script the way GitLab Runner runs job scripts: in a subshell with `set -eo pipefail`, after
      # `.default-utils-before_script` sourced scripts/utils.sh.
      def run_script(shell_command, script)
        script_path = File.join(tmp_dir, 'job_script.sh')
        File.write(script_path, script)

        Open3.capture3(
          env, *shell_command, '-c',
          "( trap 'exit 1' TERM\nset -eo pipefail\n. '#{utils_path}'\n. '#{script_path}'\n) < /dev/null"
        )
      end

      it 'runs the command and exports a span for it' do
        stdout, _, status = run_script(shell_command, 'otel_span verify-tff-mapping -- echo ran')

        expect(status.exitstatus).to eq(0)
        expect(stdout).to eq("ran\n")
        expect(exported_spans).to contain_exactly(
          a_hash_including('name' => 'verify-tff-mapping', 'command' => 'echo', 'exit-code' => '0')
        )
        expect(Integer(exported_spans.first['start-time-ns'])).to be_positive
      end

      it 'runs shell functions in the current shell' do
        stdout, _, status = run_script(shell_command, <<~SCRIPT)
          prepare() { export PREPARED=yes; cd /; }
          otel_span prepare -- prepare
          echo "${PREPARED} ${PWD}"
        SCRIPT

        expect(status.exitstatus).to eq(0)
        expect(stdout).to eq("yes /\n")
      end

      it 'defaults the span name to the command basename' do
        stdout, _, status = run_script(shell_command, 'otel_span -- /bin/echo ran')

        expect(status.exitstatus).to eq(0)
        expect(stdout).to eq("ran\n")
        expect(exported_spans).to contain_exactly(
          a_hash_including('name' => 'echo', 'command' => '/bin/echo', 'exit-code' => '0')
        )
      end

      it 'defaults the span name to the shell function name and preserves its side effects' do
        stdout, _, status = run_script(shell_command, <<~SCRIPT)
          prepare() { export PREPARED=yes; }
          otel_span -- prepare
          echo "$PREPARED"
        SCRIPT

        expect(status.exitstatus).to eq(0)
        expect(stdout).to eq("yes\n")
        expect(exported_spans.first).to include('name' => 'prepare', 'command' => 'prepare')
      end

      it 'uses the interpreter name without including its arguments' do
        stdout, _, status = run_script(shell_command, "otel_span -- ruby -e 'puts :ran'")

        expect(status.exitstatus).to eq(0)
        expect(stdout).to eq("ran\n")
        expect(exported_spans.first).to include('name' => 'ruby', 'command' => 'ruby')
      end

      it 'supports nested wrappers with default names' do
        _, _, status = run_script(shell_command, 'otel_span -- otel_span -- true')

        expect(status.exitstatus).to eq(0)
        expect(exported_spans.map { |span| span['name'] }).to eq(%w[true otel_span])
        expect(exported_spans.first['parent-traceparent'].split('-')[2]).to eq(exported_spans.last['span-id'])
      end

      it 'passes command flags, separators, empty arguments, and whitespace unchanged' do
        stdout, _, status = run_script(shell_command, <<~SCRIPT)
          otel_span arguments -- ruby -e 'puts ARGV.inspect' -- --verbose -- '' 'two words'
        SCRIPT

        expect(status.exitstatus).to eq(0)
        expect(stdout).to eq("[\"--verbose\", \"--\", \"\", \"two words\"]\n")
        expect(exported_spans.first).to include('command' => 'ruby', 'exit-code' => '0')
      end

      context 'with an invalid invocation' do
        where(:invocation) do
          [
            'otel_span',
            'otel_span name',
            'otel_span name --',
            'otel_span --',
            "otel_span -- ''",
            'otel_span name echo ran',
            "otel_span '' -- echo ran",
            "otel_span name -- ''"
          ]
        end

        with_them do
          it 'returns a usage error without running a command or exporting' do
            stdout, stderr, status = run_script(shell_command, invocation)

            expect(status.exitstatus).to eq(2)
            expect(stdout).to be_empty
            expect(stderr).to include('Usage: otel_span [NAME] -- COMMAND [ARGS...]')
            expect(exported_spans).to be_empty
          end
        end
      end

      it 'stops the job with the exit status of a failing command and exports an error span' do
        stdout, _, status = run_script(shell_command, <<~SCRIPT)
          otel_span failing -- sh -c 'exit 3'
          echo not reached
        SCRIPT

        expect(status.exitstatus).to eq(3)
        expect(stdout).not_to include('not reached')
        expect(exported_spans).to contain_exactly(a_hash_including('name' => 'failing', 'exit-code' => '3'))
      end

      it 'keeps set -e behavior inside wrapped shell functions' do
        stdout, _, status = run_script(shell_command, <<~SCRIPT)
          steps() { false; echo not reached; }
          otel_span steps -- steps
        SCRIPT

        expect(status.exitstatus).to eq(1)
        expect(stdout).not_to include('not reached')
        expect(exported_spans).to contain_exactly(a_hash_including('name' => 'steps', 'exit-code' => '1'))
      end

      it 'returns the exit status of a failing command when the failure is handled' do
        stdout, _, status = run_script(shell_command, "otel_span failing -- sh -c 'exit 3' || echo \"handled $?\"")

        expect(status.exitstatus).to eq(0)
        expect(stdout).to eq("handled 3\n")
        expect(exported_spans).to contain_exactly(a_hash_including('name' => 'failing', 'exit-code' => '3'))
      end

      it 'does not change variables of the wrapped command that share a name with its arguments' do
        stdout, _, status = run_script(shell_command, <<~SCRIPT)
          set_name() { span_name=job; }
          otel_span renamed -- set_name
          echo "${span_name}"
        SCRIPT

        expect(status.exitstatus).to eq(0)
        expect(stdout).to eq("job\n")
      end

      it 'leaves an existing EXIT trap in place' do
        stdout, _, status = run_script(shell_command, <<~SCRIPT)
          trap 'echo job trap' EXIT
          otel_span succeeding -- true
          otel_span failing -- sh -c 'exit 4'
        SCRIPT

        expect(status.exitstatus).to eq(4)
        expect(stdout).to eq("job trap\n")
        expect(exported_spans).to contain_exactly(a_hash_including('name' => 'succeeding', 'exit-code' => '0'))
      end

      it 'keeps an EXIT trap set by the wrapped command' do
        stdout, _, status = run_script(shell_command, <<~SCRIPT)
          set_cleanup() { trap 'echo job cleanup' EXIT; }
          otel_span cleanup -- set_cleanup
        SCRIPT

        expect(status.exitstatus).to eq(0)
        expect(stdout).to eq("job cleanup\n")
        expect(exported_spans).to contain_exactly(a_hash_including('name' => 'cleanup', 'exit-code' => '0'))
      end

      context 'when the temporary directory is unavailable' do
        before do
          env['TMPDIR'] = File.join(tmp_dir, 'missing')
        end

        it 'keeps the existing EXIT trap and the exit status of the job' do
          stdout, _, status = run_script(shell_command, <<~SCRIPT)
            trap 'echo job cleanup' EXIT
            otel_span succeeding -- true
            exit 42
          SCRIPT

          expect(status.exitstatus).to eq(42)
          expect(stdout).to eq("job cleanup\n")
          expect(exported_spans).to contain_exactly(a_hash_including('name' => 'succeeding', 'exit-code' => '0'))
        end
      end

      it 'keeps the existing EXIT trap when noclobber is set' do
        stdout, _, status = run_script(shell_command, <<~SCRIPT)
          set -o noclobber
          trap 'echo job cleanup' EXIT
          otel_span succeeding -- true
        SCRIPT

        expect(status.exitstatus).to eq(0)
        expect(stdout).to eq("job cleanup\n")
        expect(exported_spans).to contain_exactly(a_hash_including('name' => 'succeeding', 'exit-code' => '0'))
      end

      it 'does not leave its EXIT trap after the command succeeds' do
        stdout, _, status = run_script(shell_command, "otel_span succeeding -- true\ntrap")

        expect(status.exitstatus).to eq(0)
        expect(stdout).not_to include('EXIT')
      end

      it 'exports nested spans with their own names' do
        _, _, status = run_script(shell_command, 'otel_span outer -- otel_span inner -- true')

        expect(status.exitstatus).to eq(0)
        expect(exported_spans).to contain_exactly(
          a_hash_including('name' => 'inner', 'command' => 'true'),
          a_hash_including('name' => 'outer', 'command' => 'otel_span')
        )
      end

      it 'propagates its span context to a child executable and restores the caller context' do
        stdout, _, status = run_script(shell_command, <<~SCRIPT)
          otel_span child -- ruby -e 'puts ENV.fetch("CI_TRACEPARENT"); puts ENV.fetch("CI_TRACESTATE")'
          echo "$CI_TRACEPARENT"
        SCRIPT

        span = exported_spans.first
        expect(status.exitstatus).to eq(0)
        expect(stdout.lines.map(&:chomp)).to eq([
          "00-000000000000000000000000acb87def-#{span['span-id']}-01",
          env['CI_TRACESTATE'],
          env['CI_TRACEPARENT']
        ])
        expect(span).to include('parent-traceparent' => env['CI_TRACEPARENT'], 'tracestate' => env['CI_TRACESTATE'])
      end

      it 'parents nested wrappers to the enclosing span and restores context for sibling commands' do
        stdout, _, status = run_script(shell_command, <<~SCRIPT)
          steps() {
            echo "$CI_TRACEPARENT"
            otel_span inner -- ruby -e 'puts ENV.fetch("CI_TRACEPARENT")'
            echo "$CI_TRACEPARENT"
          }
          otel_span outer -- steps
          otel_span sibling -- true
          echo "$CI_TRACEPARENT"
        SCRIPT

        inner, outer, sibling = exported_spans
        outer_context = "00-000000000000000000000000acb87def-#{outer['span-id']}-01"
        expect(status.exitstatus).to eq(0)
        expect(inner['parent-traceparent']).to eq(outer_context)
        expect(outer['parent-traceparent']).to eq(env['CI_TRACEPARENT'])
        expect(sibling['parent-traceparent']).to eq(env['CI_TRACEPARENT'])
        expect(stdout.lines.map(&:chomp)).to eq([
          outer_context,
          "00-000000000000000000000000acb87def-#{inner['span-id']}-01",
          outer_context,
          env['CI_TRACEPARENT']
        ])
      end

      it 'restores the caller context after a handled failure' do
        stdout, _, status = run_script(shell_command, <<~SCRIPT)
          otel_span failing -- sh -c 'exit 3' || echo "$CI_TRACEPARENT"
        SCRIPT

        expect(status.exitstatus).to eq(0)
        expect(stdout.chomp).to eq(env['CI_TRACEPARENT'])
        expect(exported_spans.first).to include('parent-traceparent' => env['CI_TRACEPARENT'], 'exit-code' => '3')
      end

      it 'exports shell-local context to children without leaking their context changes' do
        stdout, _, status = run_script(shell_command, <<~SCRIPT)
          unset CI_TRACEPARENT CI_TRACESTATE
          CI_TRACEPARENT='#{env['CI_TRACEPARENT']}'
          CI_TRACESTATE='#{env['CI_TRACESTATE']}'
          steps() {
            ruby -e 'puts ENV.fetch("CI_TRACEPARENT"); puts ENV.fetch("CI_TRACESTATE")'
            CI_TRACEPARENT=changed
            CI_TRACESTATE=changed
          }
          otel_span child -- steps
          echo "$CI_TRACEPARENT $CI_TRACESTATE"
        SCRIPT

        expect(status.exitstatus).to eq(0)
        expect(stdout.lines.map(&:chomp)).to eq([
          "00-000000000000000000000000acb87def-#{exported_spans.first['span-id']}-01",
          env['CI_TRACESTATE'],
          "#{env['CI_TRACEPARENT']} #{env['CI_TRACESTATE']}"
        ])
        expect(exported_spans.first).to include('tracestate' => env['CI_TRACESTATE'])
      end

      it 'exports the preallocated span with the original parent when the shell exits' do
        stdout, _, status = run_script(shell_command, <<~SCRIPT)
          otel_span failing -- sh -c 'echo "$CI_TRACEPARENT"; exit 3'
        SCRIPT

        expect(status.exitstatus).to eq(3)
        expect(stdout.chomp.split('-')[2]).to eq(exported_spans.first['span-id'])
        expect(exported_spans.first).to include('parent-traceparent' => env['CI_TRACEPARENT'], 'exit-code' => '3')
      end

      context 'when the trace context is invalid' do
        before do
          env['CI_TRACEPARENT'] = 'invalid'
        end

        it 'runs the command with unchanged context and does not export' do
          stdout, _, status = run_script(shell_command, 'otel_span child -- sh -c \'echo "$CI_TRACEPARENT"\'')

          expect(status.exitstatus).to eq(0)
          expect(stdout.chomp).to eq('invalid')
          expect(exported_spans).to be_empty
        end
      end

      context 'when GLCI_OTEL_ENDPOINT is not set' do
        before do
          env['GLCI_OTEL_ENDPOINT'] = nil
        end

        it 'only runs the command, without a warning' do
          stdout, stderr, status = run_script(shell_command, 'otel_span verify-tff-mapping -- echo ran')

          expect(status.exitstatus).to eq(0)
          expect(stdout).to eq("ran\n")
          expect(stderr).to be_empty
          expect(exported_spans).to be_empty
        end

        it 'runs commands with default names without exporting' do
          stdout, _, status = run_script(shell_command, 'otel_span -- echo ran')

          expect(status.exitstatus).to eq(0)
          expect(stdout).to eq("ran\n")
          expect(exported_spans).to be_empty
        end
      end

      context 'when the exporter does not exist' do
        before do
          env['GLCI_OTEL_SPAN_EXPORTER'] = File.join(tmp_dir, 'missing.rb')
        end

        it 'runs the command with a warning' do
          stdout, stderr, status = run_script(shell_command, 'otel_span verify-tff-mapping -- sh -c "exit 3"')

          expect(status.exitstatus).to eq(3)
          expect(stdout).to be_empty
          expect(stderr).to include('WARNING: otel_span: Ruby or the span exporter is unavailable, ' \
            'running verify-tff-mapping without a span')
        end
      end

      context 'when Ruby is not available' do
        before do
          shell_path = ENV.fetch('PATH').split(File::PATH_SEPARATOR)
            .map { |dir| File.join(dir, shell_command.first) }
            .find { |path| File.executable?(path) }
          bin_dir = File.join(tmp_dir, 'bin')
          FileUtils.mkdir_p(bin_dir)
          File.symlink(shell_path, File.join(bin_dir, shell_command.first))
          env['PATH'] = bin_dir
        end

        it 'runs the command with a warning' do
          stdout, stderr, status = run_script(shell_command, 'otel_span -- echo ran')

          expect(status.exitstatus).to eq(0)
          expect(stdout).to eq("ran\n")
          expect(stderr).to include('WARNING: otel_span: Ruby or the span exporter is unavailable, ' \
            'running echo without a span')
        end
      end
    end
  end
end
