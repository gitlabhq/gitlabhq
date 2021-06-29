# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::PodLogs::ElasticsearchService do
  let_it_be(:cluster) { create(:cluster, :provided_by_gcp, environment_scope: '*') }

  let(:namespace) { 'autodevops-deploy-9-production' }

  let(:pod_name) { 'pod-1' }
  let(:container_name) { 'container-1' }
  let(:search) { 'foo -bar' }
  let(:start_time) { '2019-01-02T12:13:14+02:00' }
  let(:end_time) { '2019-01-03T12:13:14+02:00' }
  let(:cursor) { '9999934,1572449784442' }
  let(:params) { {} }
  let(:expected_logs) do
    [
      { message: "Log 1", timestamp: "2019-12-13T14:04:22.123456Z" },
      { message: "Log 2", timestamp: "2019-12-13T14:04:23.123456Z" },
      { message: "Log 3", timestamp: "2019-12-13T14:04:24.123456Z" }
    ]
  end

  let(:raw_pods) do
    [
      {
        name: pod_name,
        container_names: [container_name, "#{container_name}-1"]
      }
    ]
  end

  subject { described_class.new(cluster, namespace, params: params) }

  describe '#get_raw_pods' do
    before do
      create(:clusters_integrations_elastic_stack, cluster: cluster)
    end

    it 'returns success with elasticsearch response' do
      allow_any_instance_of(::Clusters::Integrations::ElasticStack)
        .to receive(:elasticsearch_client)
        .and_return(Elasticsearch::Transport::Client.new)
      allow_any_instance_of(::Gitlab::Elasticsearch::Logs::Pods)
        .to receive(:pods)
        .with(namespace)
        .and_return(raw_pods)

      result = subject.send(:get_raw_pods, {})

      expect(result[:status]).to eq(:success)
      expect(result[:raw_pods]).to eq(raw_pods)
    end

    it 'returns an error when ES is unreachable' do
      allow_any_instance_of(::Clusters::Integrations::ElasticStack)
        .to receive(:elasticsearch_client)
        .and_return(nil)

      result = subject.send(:get_raw_pods, {})

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('Unable to connect to Elasticsearch')
    end

    it 'handles server errors from elasticsearch' do
      allow_any_instance_of(::Clusters::Integrations::ElasticStack)
        .to receive(:elasticsearch_client)
        .and_return(Elasticsearch::Transport::Client.new)
      allow_any_instance_of(::Gitlab::Elasticsearch::Logs::Pods)
        .to receive(:pods)
        .and_raise(Elasticsearch::Transport::Transport::Errors::ServiceUnavailable.new)

      result = subject.send(:get_raw_pods, {})

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('Elasticsearch returned status code: ServiceUnavailable')
    end
  end

  describe '#check_times' do
    context 'with start and end provided and valid' do
      let(:params) do
        {
          'start_time' => start_time,
          'end_time' => end_time
        }
      end

      it 'returns success with times' do
        result = subject.send(:check_times, {})

        expect(result[:status]).to eq(:success)
        expect(result[:start_time]).to eq(start_time)
        expect(result[:end_time]).to eq(end_time)
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
          'start_time' => start_time,
          'end_time' => 'invalid date'
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
          'start_time' => 'invalid date',
          'end_time' => end_time
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

    context 'with search provided and invalid' do
      let(:params) do
        {
            'search' => { term: "foo-bar" }
        }
      end

      it 'returns error' do
        result = subject.send(:check_search, {})

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq("Invalid search parameter")
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

  describe '#check_cursor' do
    context 'with cursor provided and valid' do
      let(:params) do
        {
          'cursor' => cursor
        }
      end

      it 'returns success with cursor' do
        result = subject.send(:check_cursor, {})

        expect(result[:status]).to eq(:success)
        expect(result[:cursor]).to eq(cursor)
      end
    end

    context 'with cursor provided and invalid' do
      let(:params) do
        {
            'cursor' => { term: "foo-bar" }
        }
      end

      it 'returns error' do
        result = subject.send(:check_cursor, {})

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq("Invalid cursor parameter")
      end
    end

    context 'with cursor not provided' do
      let(:params) do
        {}
      end

      it 'returns success with nothing else' do
        result = subject.send(:check_cursor, {})

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
        start_time: start_time,
        end_time: end_time,
        cursor: cursor
      }
    end

    let(:expected_cursor) { '9999934,1572449784442' }

    before do
      create(:clusters_integrations_elastic_stack, cluster: cluster)
    end

    it 'returns the logs' do
      allow_any_instance_of(::Clusters::Integrations::ElasticStack)
        .to receive(:elasticsearch_client)
        .and_return(Elasticsearch::Transport::Client.new)
      allow_any_instance_of(::Gitlab::Elasticsearch::Logs::Lines)
        .to receive(:pod_logs)
        .with(namespace, pod_name: pod_name, container_name: container_name, search: search, start_time: start_time, end_time: end_time, cursor: cursor, chart_above_v2: true)
        .and_return({ logs: expected_logs, cursor: expected_cursor })

      result = subject.send(:pod_logs, result_arg)

      expect(result[:status]).to eq(:success)
      expect(result[:logs]).to eq(expected_logs)
      expect(result[:cursor]).to eq(expected_cursor)
    end

    it 'returns an error when ES is unreachable' do
      allow_any_instance_of(::Clusters::Integrations::ElasticStack)
        .to receive(:elasticsearch_client)
        .and_return(nil)

      result = subject.send(:pod_logs, result_arg)

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('Unable to connect to Elasticsearch')
    end

    it 'handles server errors from elasticsearch' do
      allow_any_instance_of(::Clusters::Integrations::ElasticStack)
        .to receive(:elasticsearch_client)
        .and_return(Elasticsearch::Transport::Client.new)
      allow_any_instance_of(::Gitlab::Elasticsearch::Logs::Lines)
        .to receive(:pod_logs)
        .and_raise(Elasticsearch::Transport::Transport::Errors::ServiceUnavailable.new)

      result = subject.send(:pod_logs, result_arg)

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('Elasticsearch returned status code: ServiceUnavailable')
    end

    it 'handles cursor errors from elasticsearch' do
      allow_any_instance_of(::Clusters::Integrations::ElasticStack)
        .to receive(:elasticsearch_client)
        .and_return(Elasticsearch::Transport::Client.new)
      allow_any_instance_of(::Gitlab::Elasticsearch::Logs::Lines)
        .to receive(:pod_logs)
        .and_raise(::Gitlab::Elasticsearch::Logs::Lines::InvalidCursor.new)

      result = subject.send(:pod_logs, result_arg)

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('Invalid cursor value provided')
    end
  end
end
