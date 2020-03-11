# frozen_string_literal: true

require 'spec_helper'

describe ::PodLogs::ElasticsearchService do
  let_it_be(:cluster) { create(:cluster, :provided_by_gcp, environment_scope: '*') }
  let(:namespace) { 'autodevops-deploy-9-production' }

  let(:pod_name) { 'pod-1' }
  let(:container_name) { 'container-1' }
  let(:search) { 'foo -bar' }
  let(:start_time) { '2019-01-02T12:13:14+02:00' }
  let(:end_time) { '2019-01-03T12:13:14+02:00' }
  let(:params) { {} }
  let(:expected_logs) do
    [
      { message: "Log 1", timestamp: "2019-12-13T14:04:22.123456Z" },
      { message: "Log 2", timestamp: "2019-12-13T14:04:23.123456Z" },
      { message: "Log 3", timestamp: "2019-12-13T14:04:24.123456Z" }
    ]
  end

  subject { described_class.new(cluster, namespace, params: params) }

  describe '#check_times' do
    context 'with start and end provided and valid' do
      let(:params) do
        {
          'start' => start_time,
          'end' => end_time
        }
      end

      it 'returns success with times' do
        result = subject.send(:check_times, {})

        expect(result[:status]).to eq(:success)
        expect(result[:start]).to eq(start_time)
        expect(result[:end]).to eq(end_time)
      end
    end

    context 'with start and end not provided' do
      let(:params) do
        {}
      end

      it 'returns success with nothing else' do
        result = subject.send(:check_times, {})

        expect(result.keys.length).to eq(1)
        expect(result[:status]).to eq(:success)
      end
    end

    context 'with start valid and end invalid' do
      let(:params) do
        {
          'start' => start_time,
          'end' => 'invalid date'
        }
      end

      it 'returns error' do
        result = subject.send(:check_times, {})

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq('Invalid start or end time format')
      end
    end

    context 'with start invalid and end valid' do
      let(:params) do
        {
          'start' => 'invalid date',
          'end' => end_time
        }
      end

      it 'returns error' do
        result = subject.send(:check_times, {})

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq('Invalid start or end time format')
      end
    end
  end

  describe '#check_search' do
    context 'with search provided and valid' do
      let(:params) do
        {
          'search' => search
        }
      end

      it 'returns success with search' do
        result = subject.send(:check_search, {})

        expect(result[:status]).to eq(:success)
        expect(result[:search]).to eq(search)
      end
    end

    context 'with search not provided' do
      let(:params) do
        {}
      end

      it 'returns success with nothing else' do
        result = subject.send(:check_search, {})

        expect(result.keys.length).to eq(1)
        expect(result[:status]).to eq(:success)
      end
    end
  end

  describe '#pod_logs' do
    let(:result_arg) do
      {
        pod_name: pod_name,
        container_name: container_name,
        search: search,
        start: start_time,
        end: end_time
      }
    end

    before do
      create(:clusters_applications_elastic_stack, :installed, cluster: cluster)
    end

    it 'returns the logs' do
      allow_any_instance_of(::Clusters::Applications::ElasticStack)
        .to receive(:elasticsearch_client)
        .and_return(Elasticsearch::Transport::Client.new)
      allow_any_instance_of(::Gitlab::Elasticsearch::Logs)
        .to receive(:pod_logs)
        .with(namespace, pod_name, container_name, search, start_time, end_time)
        .and_return(expected_logs)

      result = subject.send(:pod_logs, result_arg)

      expect(result[:status]).to eq(:success)
      expect(result[:logs]).to eq(expected_logs)
    end

    it 'returns an error when ES is unreachable' do
      allow_any_instance_of(::Clusters::Applications::ElasticStack)
        .to receive(:elasticsearch_client)
        .and_return(nil)

      result = subject.send(:pod_logs, result_arg)

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('Unable to connect to Elasticsearch')
    end

    it 'handles server errors from elasticsearch' do
      allow_any_instance_of(::Clusters::Applications::ElasticStack)
        .to receive(:elasticsearch_client)
        .and_return(Elasticsearch::Transport::Client.new)
      allow_any_instance_of(::Gitlab::Elasticsearch::Logs)
        .to receive(:pod_logs)
        .and_raise(Elasticsearch::Transport::Transport::Errors::ServiceUnavailable.new)

      result = subject.send(:pod_logs, result_arg)

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('Elasticsearch returned status code: ServiceUnavailable')
    end
  end
end
