# frozen_string_literal: true

require 'rake_helper'

describe 'gitlab:generate_sample_prometheus_data rake task' do
  let(:cluster) { create(:cluster, :provided_by_user, :project) }
  let(:environment) { create(:environment, project: cluster.project) }
  let(:sample_query_file) { File.join(Rails.root, Metrics::SampleMetricsService::DIRECTORY, 'test_query_result.yml') }
  let!(:metric) { create(:prometheus_metric, project: cluster.project, identifier: 'test_query_result') }

  around do |example|
    example.run
  ensure
    FileUtils.rm(sample_query_file)
  end

  it 'creates the file correctly' do
    Rake.application.rake_require 'tasks/gitlab/generate_sample_prometheus_data'
    allow(Environment).to receive(:find).and_return(environment)
    allow(environment).to receive_message_chain(:prometheus_adapter, :prometheus_client, :query_range) { sample_query_result[30] }
    run_rake_task('gitlab:generate_sample_prometheus_data', [environment.id])

    expect(File.exist?(sample_query_file)).to be true

    query_file_content = YAML.load_file(sample_query_file)

    expect(query_file_content).to eq(sample_query_result)
  end
end

def sample_query_result
  file = File.join(Rails.root, 'spec/fixtures/gitlab/sample_metrics', 'sample_metric_query_result.yml')
  YAML.load_file(File.expand_path(file, __dir__))
end
