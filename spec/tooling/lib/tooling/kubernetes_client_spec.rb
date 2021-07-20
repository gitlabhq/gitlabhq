# frozen_string_literal: true

require_relative '../../../../tooling/lib/tooling/kubernetes_client'

RSpec.describe Tooling::KubernetesClient do
  let(:namespace) { 'review-apps' }
  let(:release_name) { 'my-release' }
  let(:pod_for_release) { "pod-my-release-abcd" }
  let(:raw_resource_names_str) { "NAME\nfoo\n#{pod_for_release}\nbar" }
  let(:raw_resource_names) { raw_resource_names_str.lines.map(&:strip) }

  subject { described_class.new(namespace: namespace) }

  describe 'RESOURCE_LIST' do
    it 'returns the correct list of resources separated by commas' do
      expect(described_class::RESOURCE_LIST).to eq('ingress,svc,pdb,hpa,deploy,statefulset,job,pod,secret,configmap,pvc,secret,clusterrole,clusterrolebinding,role,rolebinding,sa,crd')
    end
  end

  describe '#cleanup_by_release' do
    before do
      allow(subject).to receive(:raw_resource_names).and_return(raw_resource_names)
    end

    shared_examples 'a kubectl command to delete resources' do
      let(:wait) { true }
      let(:release_names_in_command) { release_name.respond_to?(:join) ? %(-l 'release in (#{release_name.join(', ')})') : %(-l release="#{release_name}") }

      specify do
        expect(Gitlab::Popen).to receive(:popen_with_detail)
          .with(["kubectl delete #{described_class::RESOURCE_LIST} " +
            %(--namespace "#{namespace}" --now --ignore-not-found --wait=#{wait} #{release_names_in_command})])
          .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: true)))

        expect(Gitlab::Popen).to receive(:popen_with_detail)
          .with([%(kubectl delete --namespace "#{namespace}" --ignore-not-found #{pod_for_release})])
          .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: true)))

        # We're not verifying the output here, just silencing it
        expect { subject.cleanup_by_release(release_name: release_name) }.to output.to_stdout
      end
    end

    it 'raises an error if the Kubernetes command fails' do
      expect(Gitlab::Popen).to receive(:popen_with_detail)
        .with(["kubectl delete #{described_class::RESOURCE_LIST} " +
          %(--namespace "#{namespace}" --now --ignore-not-found --wait=true -l release="#{release_name}")])
        .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: false)))

      expect { subject.cleanup_by_release(release_name: release_name) }.to raise_error(described_class::CommandFailedError)
    end

    it_behaves_like 'a kubectl command to delete resources'

    context 'with multiple releases' do
      let(:release_name) { %w[my-release my-release-2] }

      it_behaves_like 'a kubectl command to delete resources'
    end

    context 'with `wait: false`' do
      let(:wait) { false }

      it_behaves_like 'a kubectl command to delete resources'
    end
  end

  describe '#cleanup_by_created_at' do
    let(:two_days_ago) { Time.now - 3600 * 24 * 2 }
    let(:resource_type) { 'pvc' }
    let(:resource_names) { [pod_for_release] }

    before do
      allow(subject).to receive(:resource_names_created_before).with(resource_type: resource_type, created_before: two_days_ago).and_return(resource_names)
    end

    shared_examples 'a kubectl command to delete resources by older than given creation time' do
      let(:wait) { true }
      let(:release_names_in_command) { resource_names.join(' ') }

      specify do
        expect(Gitlab::Popen).to receive(:popen_with_detail)
          .with(["kubectl delete #{resource_type} ".squeeze(' ') +
            %(--namespace "#{namespace}" --now --ignore-not-found --wait=#{wait} #{release_names_in_command})])
          .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: true)))

        # We're not verifying the output here, just silencing it
        expect { subject.cleanup_by_created_at(resource_type: resource_type, created_before: two_days_ago) }.to output.to_stdout
      end
    end

    it 'raises an error if the Kubernetes command fails' do
      expect(Gitlab::Popen).to receive(:popen_with_detail)
        .with(["kubectl delete #{resource_type} " +
          %(--namespace "#{namespace}" --now --ignore-not-found --wait=true #{pod_for_release})])
        .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: false)))

      expect { subject.cleanup_by_created_at(resource_type: resource_type, created_before: two_days_ago) }.to raise_error(described_class::CommandFailedError)
    end

    it_behaves_like 'a kubectl command to delete resources by older than given creation time'

    context 'with multiple resource names' do
      let(:resource_names) { %w[pod-1 pod-2] }

      it_behaves_like 'a kubectl command to delete resources by older than given creation time'
    end

    context 'with `wait: false`' do
      let(:wait) { false }

      it_behaves_like 'a kubectl command to delete resources by older than given creation time'
    end

    context 'with no resource_type given' do
      let(:resource_type) { nil }

      it_behaves_like 'a kubectl command to delete resources by older than given creation time'
    end

    context 'with multiple resource_type given' do
      let(:resource_type) { 'pvc,service' }

      it_behaves_like 'a kubectl command to delete resources by older than given creation time'
    end

    context 'with no resources found' do
      let(:resource_names) { [] }

      it 'does not call #delete_by_exact_names' do
        expect(subject).not_to receive(:delete_by_exact_names)

        subject.cleanup_by_created_at(resource_type: resource_type, created_before: two_days_ago)
      end
    end
  end

  describe '#cleanup_review_app_namespaces' do
    let(:two_days_ago) { Time.now - 3600 * 24 * 2 }
    let(:namespaces) { %w[review-abc-123 review-xyz-789] }

    subject { described_class.new(namespace: nil) }

    before do
      allow(subject).to receive(:review_app_namespaces_created_before).with(created_before: two_days_ago).and_return(namespaces)
    end

    shared_examples 'a kubectl command to delete namespaces older than given creation time' do
      let(:wait) { true }

      specify do
        expect(Gitlab::Popen).to receive(:popen_with_detail)
                                   .with(["kubectl delete namespace " +
                                            %(--now --ignore-not-found --wait=#{wait} #{namespaces.join(' ')})])
                                   .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: true)))

        # We're not verifying the output here, just silencing it
        expect { subject.cleanup_review_app_namespaces(created_before: two_days_ago) }.to output.to_stdout
      end
    end

    it_behaves_like 'a kubectl command to delete namespaces older than given creation time'

    it 'raises an error if the Kubernetes command fails' do
      expect(Gitlab::Popen).to receive(:popen_with_detail)
                                 .with(["kubectl delete namespace " +
                                          %(--now --ignore-not-found --wait=true #{namespaces.join(' ')})])
                                 .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: false)))

      expect { subject.cleanup_review_app_namespaces(created_before: two_days_ago) }.to raise_error(described_class::CommandFailedError)
    end

    context 'with no namespaces found' do
      let(:namespaces) { [] }

      it 'does not call #delete_namespaces_by_exact_names' do
        expect(subject).not_to receive(:delete_namespaces_by_exact_names)

        subject.cleanup_review_app_namespaces(created_before: two_days_ago)
      end
    end
  end

  describe '#raw_resource_names' do
    it 'calls kubectl to retrieve the resource names' do
      expect(Gitlab::Popen).to receive(:popen_with_detail)
        .with(["kubectl get #{described_class::RESOURCE_LIST} " +
          %(--namespace "#{namespace}" -o name)])
        .and_return(Gitlab::Popen::Result.new([], raw_resource_names_str, '', double(success?: true)))

      expect(subject.__send__(:raw_resource_names)).to eq(raw_resource_names)
    end
  end

  describe '#resource_names_created_before' do
    let(:three_days_ago) { Time.now - 3600 * 24 * 3 }
    let(:two_days_ago) { Time.now - 3600 * 24 * 2 }
    let(:pvc_created_three_days_ago) { 'pvc-created-three-days-ago' }
    let(:resource_type) { 'pvc' }
    let(:raw_resources) do
      {
        items: [
          {
            apiVersion: "v1",
            kind: "PersistentVolumeClaim",
            metadata: {
                creationTimestamp: three_days_ago,
                name: pvc_created_three_days_ago
            }
          },
          {
            apiVersion: "v1",
            kind: "PersistentVolumeClaim",
            metadata: {
                creationTimestamp: Time.now,
                name: 'another-pvc'
            }
          }
        ]
      }.to_json
    end

    shared_examples 'a kubectl command to retrieve resource names sorted by creationTimestamp' do
      specify do
        expect(Gitlab::Popen).to receive(:popen_with_detail)
          .with(["kubectl get #{resource_type} ".squeeze(' ') +
            %(--namespace "#{namespace}" ) +
            "--sort-by='{.metadata.creationTimestamp}' -o json"])
          .and_return(Gitlab::Popen::Result.new([], raw_resources, '', double(success?: true)))

        expect(subject.__send__(:resource_names_created_before, resource_type: resource_type, created_before: two_days_ago)).to contain_exactly(pvc_created_three_days_ago)
      end
    end

    it_behaves_like 'a kubectl command to retrieve resource names sorted by creationTimestamp'

    context 'with no resource_type given' do
      let(:resource_type) { nil }

      it_behaves_like 'a kubectl command to retrieve resource names sorted by creationTimestamp'
    end

    context 'with multiple resource_type given' do
      let(:resource_type) { 'pvc,service' }

      it_behaves_like 'a kubectl command to retrieve resource names sorted by creationTimestamp'
    end
  end

  describe '#review_app_namespaces_created_before' do
    let(:three_days_ago) { Time.now - 3600 * 24 * 3 }
    let(:two_days_ago) { Time.now - 3600 * 24 * 2 }
    let(:namespace_created_three_days_ago) { 'namespace-created-three-days-ago' }
    let(:resource_type) { 'namespace' }
    let(:raw_resources) do
      {
        items: [
          {
            apiVersion: "v1",
            kind: "Namespace",
            metadata: {
              creationTimestamp: three_days_ago,
              name: namespace_created_three_days_ago,
              labels: {
                tls: 'review-apps-tls'
              }
            }
          },
          {
            apiVersion: "v1",
            kind: "Namespace",
            metadata: {
              creationTimestamp: Time.now,
              name: 'another-pvc',
              labels: {
                tls: 'review-apps-tls'
              }
            }
          }
        ]
      }.to_json
    end

    specify do
      expect(Gitlab::Popen).to receive(:popen_with_detail)
                                 .with(["kubectl get namespace " \
                                          "-l tls=review-apps-tls " \
                                          "--sort-by='{.metadata.creationTimestamp}' -o json"])
                                 .and_return(Gitlab::Popen::Result.new([], raw_resources, '', double(success?: true)))

      expect(subject.__send__(:review_app_namespaces_created_before, created_before: two_days_ago)).to contain_exactly(namespace_created_three_days_ago)
    end
  end
end
