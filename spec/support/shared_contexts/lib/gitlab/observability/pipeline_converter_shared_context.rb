# frozen_string_literal: true

RSpec.shared_context 'with pipeline converter data' do
  let(:integration) do
    Struct.new(:otel_endpoint_url, :otel_headers, :service_name, :environment).new(
      'https://example.com/otel',
      {},
      'gitlab-ci',
      'production'
    )
  end

  let(:base_pipeline_data) do
    {
      object_attributes: {
        id: 123,
        iid: 456,
        name: 'test-pipeline',
        ref: 'main',
        sha: 'abc123',
        source: 'push',
        status: 'success',
        detailed_status: 'passed',
        created_at: Time.zone.parse('2023-01-01T10:00:00Z'),
        finished_at: Time.zone.parse('2023-01-01T10:05:00Z'),
        duration: 300000,
        queued_duration: 30000,
        protected_ref: true,
        url: 'https://gitlab.com/project/-/pipelines/123',
        stages: %w[test build deploy]
      },
      project: {
        id: 789,
        name: 'test-project',
        path_with_namespace: 'test-org/test-project',
        web_url: 'https://gitlab.com/test-org/test-project'
      },
      builds: [
        {
          id: 1,
          name: 'test-job',
          stage: 'test',
          status: 'success',
          started_at: Time.zone.parse('2023-01-01T10:01:00Z'),
          finished_at: Time.zone.parse('2023-01-01T10:03:00Z'),
          duration: 120000,
          queued_duration: 5000,
          manual: false,
          allow_failure: false,
          runner: {
            id: 1,
            description: 'test-runner',
            active: true,
            tags: %w[docker linux],
            runner_type: 'instance_type'
          },
          artifacts_file: {
            filename: 'test-results.xml',
            size: 1024
          }
        },
        {
          id: 2,
          name: 'failed-job',
          stage: 'build',
          status: 'failed',
          started_at: Time.zone.parse('2023-01-01T10:03:00Z'),
          finished_at: Time.zone.parse('2023-01-01T10:04:00Z'),
          duration: 60000,
          queued_duration: 2000,
          manual: true,
          allow_failure: true,
          failure_reason: 'script_failure'
        }
      ]
    }
  end

  let(:root_pipeline_id) { 123 }
  let(:expected_trace_id) { Gitlab::Ci::TraceContext.trace_id_for(root_pipeline_id) }
  let(:expected_pipeline_span_id) { Gitlab::Ci::TraceContext.span_id_for_pipeline(root_pipeline_id, 123) }
end
