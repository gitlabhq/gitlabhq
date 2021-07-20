# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::PodLogs::BaseService do
  include KubernetesHelpers

  let_it_be(:cluster) { create(:cluster, :provided_by_gcp, environment_scope: '*') }

  let(:namespace) { 'autodevops-deploy-9-production' }

  let(:pod_name) { 'pod-1' }
  let(:pod_name_2) { 'pod-2' }
  let(:container_name) { 'container-0' }
  let(:params) { {} }
  let(:raw_pods) do
    [
      {
        name: pod_name,
        container_names: %w(container-0-0 container-0-1)
      },
      {
        name: pod_name_2,
        container_names: %w(container-1-0 container-1-1)
      }
    ]
  end

  subject { described_class.new(cluster, namespace, params: params) }

  describe '#initialize' do
    let(:params) do
      {
        'container_name' => container_name,
        'another_param' => 'foo'
      }
    end

    it 'filters the parameters' do
      expect(subject.cluster).to eq(cluster)
      expect(subject.namespace).to eq(namespace)
      expect(subject.params).to eq({
        'container_name' => container_name
      })
      expect(subject.params.equal?(params)).to be(false)
    end
  end

  describe '#check_arguments' do
    context 'when cluster and namespace are provided' do
      it 'returns success' do
        result = subject.send(:check_arguments, {})

        expect(result[:status]).to eq(:success)
      end
    end

    context 'when cluster is nil' do
      let(:cluster) { nil }

      it 'returns an error' do
        result = subject.send(:check_arguments, {})

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq('Cluster does not exist')
      end
    end

    context 'when namespace is nil' do
      let(:namespace) { nil }

      it 'returns an error' do
        result = subject.send(:check_arguments, {})

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq('Namespace is empty')
      end
    end

    context 'when namespace is empty' do
      let(:namespace) { '' }

      it 'returns an error' do
        result = subject.send(:check_arguments, {})

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq('Namespace is empty')
      end
    end

    context 'when pod_name and container_name are provided' do
      let(:params) do
        {
          'pod_name' => pod_name,
          'container_name' => container_name
        }
      end

      it 'returns success' do
        result = subject.send(:check_arguments, {})

        expect(result[:status]).to eq(:success)
        expect(result[:pod_name]).to eq(pod_name)
        expect(result[:container_name]).to eq(container_name)
      end
    end

    context 'when pod_name is not a string' do
      let(:params) do
        {
            'pod_name' => { something_that_is: :not_a_string }
        }
      end

      it 'returns error' do
        result = subject.send(:check_arguments, {})

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq('Invalid pod_name')
      end
    end

    context 'when container_name is not a string' do
      let(:params) do
        {
            'container_name' => { something_that_is: :not_a_string }
        }
      end

      it 'returns error' do
        result = subject.send(:check_arguments, {})

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq('Invalid container_name')
      end
    end
  end

  describe '#get_pod_names' do
    it 'returns success with a list of pods' do
      result = subject.send(:get_pod_names, raw_pods: raw_pods)

      expect(result[:status]).to eq(:success)
      expect(result[:pods]).to eq([pod_name, pod_name_2])
    end
  end
end
