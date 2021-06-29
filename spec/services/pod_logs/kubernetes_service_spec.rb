# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::PodLogs::KubernetesService do
  include KubernetesHelpers

  let_it_be(:cluster) { create(:cluster, :provided_by_gcp, environment_scope: '*') }

  let(:namespace) { 'autodevops-deploy-9-production' }

  let(:pod_name) { 'pod-1' }
  let(:pod_name_2) { 'pod-2' }
  let(:container_name) { 'container-0' }
  let(:container_name_2) { 'foo-0' }
  let(:params) { {} }

  let(:raw_logs) do
    "2019-12-13T14:04:22.123456Z Log 1\n2019-12-13T14:04:23.123456Z Log 2\n" \
      "2019-12-13T14:04:24.123456Z Log 3"
  end

  let(:raw_pods) do
    [
      {
        name: pod_name,
        container_names: [container_name, "#{container_name}-1"]
      },
      {
        name: pod_name_2,
        container_names: [container_name_2, "#{container_name_2}-1"]
      }
    ]
  end

  subject { described_class.new(cluster, namespace, params: params) }

  describe '#get_raw_pods' do
    let(:service) { create(:cluster_platform_kubernetes, :configured) }

    it 'returns success with passthrough k8s response' do
      stub_kubeclient_pods(namespace)

      result = subject.send(:get_raw_pods, {})

      expect(result[:status]).to eq(:success)
      expect(result[:raw_pods]).to eq([{
        name: 'kube-pod',
        container_names: %w(container-0 container-0-1)
      }])
    end
  end

  describe '#pod_logs' do
    let(:result_arg) do
      {
        pod_name: pod_name,
        container_name: container_name
      }
    end

    let(:expected_logs) { raw_logs }
    let(:service) { create(:cluster_platform_kubernetes, :configured) }

    it 'returns the logs' do
      stub_kubeclient_logs(pod_name, namespace, container: container_name)

      result = subject.send(:pod_logs, result_arg)

      expect(result[:status]).to eq(:success)
      expect(result[:logs]).to eq(expected_logs)
    end

    it 'handles Not Found errors from k8s' do
      allow_any_instance_of(Gitlab::Kubernetes::KubeClient)
        .to receive(:get_pod_log)
        .with(any_args)
        .and_raise(Kubeclient::ResourceNotFoundError.new(404, 'Not Found', {}))

      result = subject.send(:pod_logs, result_arg)

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('Pod not found')
    end

    it 'handles HTTP errors from k8s' do
      allow_any_instance_of(Gitlab::Kubernetes::KubeClient)
        .to receive(:get_pod_log)
        .with(any_args)
        .and_raise(Kubeclient::HttpError.new(500, 'Error', {}))

      result = subject.send(:pod_logs, result_arg)

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('Kubernetes API returned status code: 500')
    end
  end

  describe '#encode_logs_to_utf8', :aggregate_failures do
    let(:service) { create(:cluster_platform_kubernetes, :configured) }
    let(:expected_logs) { '2019-12-13T14:04:22.123456Z ✔ Started logging errors to Sentry' }
    let(:raw_logs) { expected_logs.dup.force_encoding(Encoding::ASCII_8BIT) }
    let(:result) { subject.send(:encode_logs_to_utf8, result_arg) }

    let(:result_arg) do
      {
        pod_name: pod_name,
        container_name: container_name,
        logs: raw_logs
      }
    end

    it 'converts logs to utf-8' do
      expect(result[:status]).to eq(:success)
      expect(result[:logs]).to eq(expected_logs)
    end

    it 'returns error if output of encoding helper is blank' do
      allow(Gitlab::EncodingHelper).to receive(:encode_utf8).and_return('')

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('Unable to convert Kubernetes logs encoding to UTF-8')
    end

    it 'returns error if output of encoding helper is nil' do
      allow(Gitlab::EncodingHelper).to receive(:encode_utf8).and_return(nil)

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('Unable to convert Kubernetes logs encoding to UTF-8')
    end

    it 'returns error if output of encoding helper is not UTF-8' do
      allow(Gitlab::EncodingHelper).to receive(:encode_utf8)
        .and_return(expected_logs.encode(Encoding::UTF_16BE))

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('Unable to convert Kubernetes logs encoding to UTF-8')
    end

    context 'when logs are nil' do
      let(:raw_logs) { nil }
      let(:expected_logs) { nil }

      it 'returns nil' do
        expect(result[:status]).to eq(:success)
        expect(result[:logs]).to eq(expected_logs)
      end
    end

    context 'when logs are blank' do
      let(:raw_logs) { (+'').force_encoding(Encoding::ASCII_8BIT) }
      let(:expected_logs) { '' }

      it 'returns blank string' do
        expect(result[:status]).to eq(:success)
        expect(result[:logs]).to eq(expected_logs)
      end
    end

    context 'when logs are already in utf-8' do
      let(:raw_logs) { expected_logs }

      it 'does not fail' do
        expect(result[:status]).to eq(:success)
        expect(result[:logs]).to eq(expected_logs)
      end
    end
  end

  describe '#split_logs' do
    let(:service) { create(:cluster_platform_kubernetes, :configured) }

    let(:expected_logs) do
      [
        { message: "Log 1", pod: 'pod-1', timestamp: "2019-12-13T14:04:22.123456Z" },
        { message: "Log 2", pod: 'pod-1', timestamp: "2019-12-13T14:04:23.123456Z" },
        { message: "Log 3", pod: 'pod-1', timestamp: "2019-12-13T14:04:24.123456Z" }
      ]
    end

    let(:result_arg) do
      {
        pod_name: pod_name,
        container_name: container_name,
        logs: raw_logs
      }
    end

    it 'returns the logs' do
      result = subject.send(:split_logs, result_arg)

      aggregate_failures do
        expect(result[:status]).to eq(:success)
        expect(result[:logs]).to eq(expected_logs)
      end
    end
  end

  describe '#check_pod_name' do
    it 'returns success if pod_name was specified' do
      result = subject.send(:check_pod_name, pod_name: pod_name, pods: [pod_name])

      expect(result[:status]).to eq(:success)
      expect(result[:pod_name]).to eq(pod_name)
    end

    it 'returns success if pod_name was not specified but there are pods' do
      result = subject.send(:check_pod_name, pod_name: nil, pods: [pod_name])

      expect(result[:status]).to eq(:success)
      expect(result[:pod_name]).to eq(pod_name)
    end

    it 'returns error if pod_name was not specified and there are no pods' do
      result = subject.send(:check_pod_name, pod_name: nil, pods: [])

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('No pods available')
    end

    it 'returns error if pod_name was specified but does not exist' do
      result = subject.send(:check_pod_name, pod_name: 'another-pod', pods: [pod_name])

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('Pod does not exist')
    end

    it 'returns error if pod_name is too long' do
      result = subject.send(:check_pod_name, pod_name: "a very long string." * 15, pods: [pod_name])

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('pod_name cannot be larger than 253 chars')
    end

    it 'returns error if pod_name is in invalid format' do
      result = subject.send(:check_pod_name, pod_name: "Invalid_pod_name", pods: [pod_name])

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('pod_name can contain only lowercase letters, digits, \'-\', and \'.\' and must start and end with an alphanumeric character')
    end
  end

  describe '#check_container_name' do
    it 'returns success if container_name was specified' do
      result = subject.send(:check_container_name,
        container_name: container_name,
        pod_name: pod_name,
        raw_pods: raw_pods
      )

      expect(result[:status]).to eq(:success)
      expect(result[:container_name]).to eq(container_name)
    end

    it 'returns success if container_name was not specified and there are containers' do
      result = subject.send(:check_container_name,
        pod_name: pod_name_2,
        raw_pods: raw_pods
      )

      expect(result[:status]).to eq(:success)
      expect(result[:container_name]).to eq(container_name_2)
    end

    it 'returns error if container_name was not specified and there are no containers on the pod' do
      raw_pods.first[:container_names] = []

      result = subject.send(:check_container_name,
        pod_name: pod_name,
        raw_pods: raw_pods
      )

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('No containers available')
    end

    it 'returns error if container_name was specified but does not exist' do
      result = subject.send(:check_container_name,
        container_name: 'foo',
        pod_name: pod_name,
        raw_pods: raw_pods
      )

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('Container does not exist')
    end

    it 'returns error if container_name is too long' do
      result = subject.send(:check_container_name,
        container_name: "a very long string." * 15,
        pod_name: pod_name,
        raw_pods: raw_pods
      )

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('container_name cannot be larger than 253 chars')
    end

    it 'returns error if container_name is in invalid format' do
      result = subject.send(:check_container_name,
        container_name: "Invalid_container_name",
        pod_name: pod_name,
        raw_pods: raw_pods
      )

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('container_name can contain only lowercase letters, digits, \'-\', and \'.\' and must start and end with an alphanumeric character')
    end
  end
end
