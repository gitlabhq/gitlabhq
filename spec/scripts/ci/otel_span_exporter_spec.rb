# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../support/webmock'
require_relative '../../../scripts/ci/otel_span_exporter'

RSpec.describe OtelSpanExporter, feature_category: :tooling do
  let(:trace_id) { '000000000000000000000000acb87def' }
  let(:job_span_id) { 'c929c65f80a6df0f' }
  let(:endpoint) { 'https://example.otel.gitlab-o11y.com:14318' }
  let(:traces_url) { "#{endpoint}/v1/traces" }
  let(:env) do
    {
      'GLCI_OTEL_ENDPOINT' => endpoint,
      'CI_TRACEPARENT' => "00-#{trace_id}-#{job_span_id}-01",
      'CI_TRACESTATE' => 'gitlab=pipeline:2;job:3',
      'CI_PIPELINE_ID' => '2',
      'CI_JOB_ID' => '3',
      'CI_JOB_NAME' => 'verify-tests-yml',
      'CI_PROJECT_ID' => '278964',
      'CI_PROJECT_NAME' => 'gitlab',
      'CI_PROJECT_NAMESPACE' => 'gitlab-org',
      'CI_PROJECT_TITLE' => 'GitLab',
      'CI_PROJECT_URL' => 'https://gitlab.com/gitlab-org/gitlab',
      'CI_SERVER_VERSION' => '19.5.0-pre'
    }
  end

  let(:exit_code) { 0 }
  let(:argv) do
    %W[
      --name verify-tff-mapping --command scripts/verify-tff-mapping
      --start-time-ns 1000 --end-time-ns 2500 --exit-code #{exit_code}
    ]
  end

  let(:stderr) { StringIO.new }

  subject(:run) { described_class.run(argv, env: env, stderr: stderr) }

  def exported_payload
    payload = nil

    expect(WebMock).to have_requested(:post, traces_url).with { |request|
      payload = Gitlab::Json::SafeParser.parse(request.body)
    }

    payload
  end

  def exported_span
    exported_payload.dig('resourceSpans', 0, 'scopeSpans', 0, 'spans', 0)
  end

  def attribute_values(attributes)
    attributes.to_h { |attribute| [attribute['key'], attribute['value'].each_value.first] }
  end

  before do
    stub_request(:post, traces_url).to_return(status: 200)
  end

  context 'when the command succeeded' do
    it 'exits successfully' do
      expect(run).to eq(0)
    end

    it 'exports a span parented to the job span' do
      run

      expect(exported_span).to include(
        'traceId' => trace_id,
        'parentSpanId' => job_span_id,
        'traceState' => 'gitlab=pipeline:2;job:3',
        'name' => 'verify-tff-mapping',
        'kind' => described_class::SPAN_KIND_INTERNAL,
        'startTimeUnixNano' => '1000',
        'endTimeUnixNano' => '2500',
        'status' => { 'code' => described_class::STATUS_CODE_OK }
      )
      expect(exported_span['spanId']).to match(/\A\h{16}\z/)
    end

    it 'records job metadata and only the command name' do
      run

      expect(attribute_values(exported_span['attributes'])).to eq(
        'cicd.pipeline.run.id' => '2',
        'cicd.pipeline.task.name' => 'verify-tests-yml',
        'cicd.pipeline.task.run.id' => '3',
        'process.executable.name' => 'verify-tff-mapping',
        'process.exit.code' => '0'
      )
    end

    it 'uses the resource attributes of the pipeline export and the recommended project attributes' do
      run

      expect(attribute_values(exported_payload.dig('resourceSpans', 0, 'resource', 'attributes'))).to eq(
        'service.name' => 'gitlab-ci',
        'service.version' => '19.5.0-pre',
        'vcs.owner.name' => 'gitlab-org',
        'vcs.provider.name' => 'gitlab',
        'vcs.repository.name' => 'GitLab',
        'gitlab.vcs.repository.id' => '278964',
        'vcs.repository.url.full' => 'https://gitlab.com/gitlab-org/gitlab',
        'gitlab.project.id' => '278964',
        'gitlab.project.name' => 'gitlab'
      )
    end
  end

  context 'when the command failed' do
    let(:exit_code) { 3 }

    it 'exits successfully' do
      expect(run).to eq(0)
    end

    it 'exports an error span' do
      run

      expect(exported_span['status']).to eq('code' => described_class::STATUS_CODE_ERROR, 'message' => 'exit status 3')
      expect(attribute_values(exported_span['attributes'])).to include('process.exit.code' => '3')
    end
  end

  context 'when the wrapper supplies the preallocated span context' do
    let(:span_id) { '1234567890abcdef' }
    let(:argv) do
      super() + ['--span-id', span_id, '--parent-traceparent', "00-#{trace_id}-#{job_span_id}-01", '--tracestate', '']
    end

    before do
      env['CI_TRACEPARENT'] = "00-#{trace_id}-#{span_id}-01"
    end

    it 'uses the supplied span ID and original parent without parenting itself' do
      run

      expect(exported_span).to include('spanId' => span_id, 'parentSpanId' => job_span_id, 'traceState' => '')
    end
  end

  describe '.run with --prepare-context' do
    let(:stdout) { StringIO.new }

    subject(:prepare_context) do
      described_class.run(['--prepare-context'], env: env, stderr: stderr, stdout: stdout)
    end

    it 'generates a child context without exporting a span' do
      expect(prepare_context).to eq(0)
      expect(stdout.string.chomp).to match(/\A00-#{trace_id}-[0-9a-f]{16}-01\z/)
      expect(stdout.string.chomp.split('-')[2]).not_to eq(job_span_id)
      expect(WebMock).not_to have_requested(:post, traces_url)
    end

    context 'with different trace flags' do
      before do
        env['CI_TRACEPARENT'] = "00-#{trace_id}-#{job_span_id}-00"
      end

      it 'preserves the flags' do
        prepare_context

        expect(stdout.string.chomp).to end_with('-00')
      end
    end

    context 'with invalid context' do
      before do
        env['CI_TRACEPARENT'] = 'invalid'
      end

      it 'does not supply a new context' do
        expect(prepare_context).to eq(0)
        expect(stdout.string).to be_empty
      end
    end

    context 'when span ID generation fails' do
      before do
        allow(SecureRandom).to receive(:hex).and_raise(RuntimeError)
      end

      it 'warns without failing the command or supplying context' do
        expect(prepare_context).to eq(0)
        expect(stdout.string).to be_empty
        expect(stderr.string).to include('span context preparation failed: RuntimeError')
      end
    end
  end

  context 'when the end time is not given' do
    let(:argv) { %w[--name verify-tff-mapping --start-time-ns 1000 --exit-code 0] }

    it 'ends the span now' do
      allow(Process).to receive(:clock_gettime).and_call_original
      allow(Process).to receive(:clock_gettime).with(Process::CLOCK_REALTIME, :nanosecond).and_return(5000)

      run

      expect(exported_span['endTimeUnixNano']).to eq('5000')
    end
  end

  context 'when the command name is not given' do
    let(:argv) { %w[--name verify-tff-mapping --start-time-ns 1000 --end-time-ns 2500 --exit-code 0] }

    it 'exports the span without the command name' do
      run

      expect(attribute_values(exported_span['attributes'])).not_to have_key('process.executable.name')
    end
  end

  context 'when the arguments are invalid' do
    where(:argv) do
      [
        [%w[--name verify-tff-mapping --start-time-ns 1000 --end-time-ns 2500]],
        [%w[--name verify-tff-mapping --start-time-ns now --end-time-ns 2500 --exit-code 0]],
        [['--name', 'verify-tff-mapping', '--start-time-ns', '', '--exit-code', '0']],
        [%w[--unknown]],
        [%w[--name test --start-time-ns 1000 --exit-code 0 --span-id invalid]],
        [%w[--name test --start-time-ns 1000 --exit-code 0 --span-id 0000000000000000]]
      ]
    end

    with_them do
      it 'warns and exits successfully without exporting a span' do
        expect(run).to eq(0)
        expect(WebMock).not_to have_requested(:post, traces_url)
        expect(stderr.string).to include('invalid arguments')
      end
    end
  end

  describe 'authentication' do
    context 'when GITLAB_OBSERVABILITY_TOKEN is set' do
      before do
        env['GITLAB_OBSERVABILITY_TOKEN'] = " ingest-token\n"
      end

      it 'sends the stripped token as a bearer token' do
        run

        expect(WebMock).to have_requested(:post, traces_url)
          .with(headers: { 'Authorization' => 'Bearer ingest-token', 'Content-Type' => 'application/json' })
      end
    end

    context 'when GITLAB_OBSERVABILITY_TOKEN contains control characters' do
      before do
        env['GITLAB_OBSERVABILITY_TOKEN'] = "ingest\rtoken"
      end

      it 'does not send an Authorization header' do
        run

        expect(WebMock).to have_requested(:post, traces_url).with { |request| !request.headers.key?('Authorization') }
      end
    end

    context 'when GITLAB_OBSERVABILITY_TOKEN is not set' do
      it 'does not send an Authorization header' do
        run

        expect(WebMock).to have_requested(:post, traces_url).with { |request| !request.headers.key?('Authorization') }
      end
    end
  end

  context 'when GLCI_OTEL_ENDPOINT has a trailing slash' do
    let(:endpoint) { 'https://example.otel.gitlab-o11y.com:14318/' }
    let(:traces_url) { 'https://example.otel.gitlab-o11y.com:14318/v1/traces' }

    it 'appends the traces path once' do
      run

      expect(WebMock).to have_requested(:post, traces_url)
    end
  end

  context 'when GLCI_OTEL_ENDPOINT is not set' do
    before do
      env.delete('GLCI_OTEL_ENDPOINT')
    end

    it 'does not export a span' do
      expect(run).to eq(0)
      expect(WebMock).not_to have_requested(:post, /v1/)
      expect(stderr.string).to be_empty
    end
  end

  context 'when CI_TRACEPARENT is invalid' do
    where(:traceparent) do
      [
        nil,
        'invalid',
        '00-000000000000000000000000ACB87DEF-c929c65f80a6df0f-01',
        '00-00000000000000000000000000000000-c929c65f80a6df0f-01',
        '00-000000000000000000000000acb87def-0000000000000000-01'
      ]
    end

    with_them do
      before do
        env['CI_TRACEPARENT'] = traceparent
      end

      it 'skips the export with a warning' do
        expect(run).to eq(0)
        expect(WebMock).not_to have_requested(:post, traces_url)
        expect(stderr.string).to include('CI_TRACEPARENT is missing or invalid')
      end
    end
  end

  describe 'export failures' do
    context 'when an invalid endpoint contains credentials' do
      let(:endpoint) { 'https://username:secret password@example.com' }

      it 'warns without disclosing the endpoint or credentials' do
        expect(run).to eq(0)
        expect(stderr.string).to include('span export failed: URI::InvalidURIError')
        expect(stderr.string).not_to include('username', 'secret password', 'example.com')
      end
    end

    context 'when the export raises an unexpected error' do
      let(:endpoint) { 'https://username:secret@example.otel.gitlab-o11y.com:14318' }

      before do
        env['GITLAB_OBSERVABILITY_TOKEN'] = 'ingest-token'
        message = "undefined method for #{endpoint} (username, secret, example.otel.gitlab-o11y.com) ingest-token"
        allow(Net::HTTP).to receive(:start).and_raise(NoMethodError, message)
      end

      it 'warns with the redacted error message' do
        expect(run).to eq(0)
        expect(stderr.string).to include(
          'span export failed: NoMethodError: undefined method for [REDACTED] ([REDACTED], [REDACTED], [REDACTED]) ' \
            '[REDACTED]'
        )
      end
    end

    context 'when the endpoint returns an error' do
      before do
        stub_request(:post, traces_url).to_return(status: 503)
      end

      it 'warns and exits successfully' do
        expect(run).to eq(0)
        expect(stderr.string).to include('span export failed with HTTP 503')
      end
    end

    context 'when the request times out' do
      before do
        env['GITLAB_OBSERVABILITY_TOKEN'] = 'ingest-token'
        stub_request(:post, traces_url).to_timeout
      end

      it 'warns without the token and exits successfully' do
        expect(run).to eq(0)
        expect(stderr.string).to include('span export failed: Net::OpenTimeout')
        expect(stderr.string).not_to include('ingest-token')
      end
    end

    context 'when the export exceeds the overall deadline' do
      before do
        allow(Timeout).to receive(:timeout).with(described_class::EXPORT_TIMEOUT_S).and_raise(Timeout::Error)
      end

      it 'warns and exits successfully' do
        expect(run).to eq(0)
        expect(stderr.string).to include('span export failed: Timeout::Error')
      end
    end
  end
end
