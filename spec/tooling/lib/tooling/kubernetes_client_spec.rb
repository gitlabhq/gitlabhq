# frozen_string_literal: true

require 'time'
require_relative '../../../../tooling/lib/tooling/kubernetes_client'

RSpec.describe Tooling::KubernetesClient do
  let(:instance)       { described_class.new }
  let(:one_day_ago)    { Time.now - 3600 * 24 * 1 }
  let(:two_days_ago)   { Time.now - 3600 * 24 * 2 }
  let(:three_days_ago) { Time.now - 3600 * 24 * 3 }

  before do
    # Global mock to ensure that no kubectl commands are run by accident in a test.
    allow(instance).to receive(:run_command)
  end

  describe '#cleanup_pvcs_by_created_at' do
    let(:pvc_1_created_at) { three_days_ago }
    let(:pvc_2_created_at) { three_days_ago }
    let(:pvc_1_namespace) { 'review-first-review-app' }
    let(:pvc_2_namespace) { 'review-second-review-app' }
    let(:kubectl_pvcs_json) do
      <<~JSON
        {
          "apiVersion": "v1",
          "items": [
              {
                  "apiVersion": "v1",
                  "kind": "PersistentVolumeClaim",
                  "metadata": {
                      "creationTimestamp": "#{pvc_1_created_at.utc.iso8601}",
                      "name": "pvc1",
                      "namespace": "#{pvc_1_namespace}"
                  }
              },
              {
                  "apiVersion": "v1",
                  "kind": "PersistentVolumeClaim",
                  "metadata": {
                      "creationTimestamp": "#{pvc_2_created_at.utc.iso8601}",
                      "name": "pvc2",
                      "namespace": "#{pvc_2_namespace}"
                  }
              }
          ]
        }
      JSON
    end

    subject { instance.cleanup_pvcs_by_created_at(created_before: two_days_ago) }

    before do
      allow(instance).to receive(:run_command).with(
        "kubectl get pvc --all-namespaces --sort-by='{.metadata.creationTimestamp}' -o json"
      ).and_return(kubectl_pvcs_json)
    end

    context 'when no pvcs are stale' do
      let(:pvc_1_created_at) { one_day_ago }
      let(:pvc_2_created_at) { one_day_ago }

      it 'does not delete any PVC' do
        expect(instance).not_to receive(:run_command).with(/kubectl delete pvc/)

        subject
      end
    end

    context 'when some pvcs are stale' do
      let(:pvc_1_created_at) { three_days_ago }
      let(:pvc_2_created_at) { three_days_ago }

      context 'when some pvcs are not in a review app namespaces' do
        let(:pvc_1_namespace) { 'review-my-review-app' }
        let(:pvc_2_namespace) { 'review-apps' } # This is not a review apps namespace, so we should not delete PVCs inside it

        it 'deletes the stale pvcs inside of review-apps namespaces only' do
          expect(instance).to receive(:run_command).with("kubectl delete pvc --namespace=#{pvc_1_namespace} --now --ignore-not-found pvc1")
          expect(instance).not_to receive(:run_command).with(/kubectl delete pvc --namespace=#{pvc_2_namespace}/)

          subject
        end
      end

      context 'when all pvcs are in review-apps namespaces' do
        let(:pvc_1_namespace) { 'review-my-review-app' }
        let(:pvc_2_namespace) { 'review-another-review-app' }

        it 'deletes all of the stale pvcs' do
          expect(instance).to receive(:run_command).with("kubectl delete pvc --namespace=#{pvc_1_namespace} --now --ignore-not-found pvc1")
          expect(instance).to receive(:run_command).with("kubectl delete pvc --namespace=#{pvc_2_namespace} --now --ignore-not-found pvc2")

          subject
        end
      end
    end
  end

  describe '#cleanup_namespaces_by_created_at' do
    let(:namespace_1_created_at) { three_days_ago }
    let(:namespace_2_created_at) { three_days_ago }
    let(:namespace_1_name) { 'review-first-review-app' }
    let(:namespace_2_name) { 'review-second-review-app' }
    let(:kubectl_namespaces_json) do
      <<~JSON
        {
          "apiVersion": "v1",
          "items": [
              {
                  "apiVersion": "v1",
                  "kind": "namespace",
                  "metadata": {
                      "creationTimestamp": "#{namespace_1_created_at.utc.iso8601}",
                      "name": "#{namespace_1_name}"
                  }
              },
              {
                  "apiVersion": "v1",
                  "kind": "namespace",
                  "metadata": {
                      "creationTimestamp": "#{namespace_2_created_at.utc.iso8601}",
                      "name": "#{namespace_2_name}"
                  }
              }
          ]
        }
      JSON
    end

    subject { instance.cleanup_namespaces_by_created_at(created_before: two_days_ago) }

    before do
      allow(instance).to receive(:run_command).with(
        "kubectl get namespace --all-namespaces --sort-by='{.metadata.creationTimestamp}' -o json"
      ).and_return(kubectl_namespaces_json)
    end

    context 'when no namespaces are stale' do
      let(:namespace_1_created_at) { one_day_ago }
      let(:namespace_2_created_at) { one_day_ago }

      it 'does not delete any namespace' do
        expect(instance).not_to receive(:run_command).with(/kubectl delete namespace/)

        subject
      end
    end

    context 'when some namespaces are stale' do
      let(:namespace_1_created_at) { three_days_ago }
      let(:namespace_2_created_at) { three_days_ago }

      context 'when some namespaces are not review app namespaces' do
        let(:namespace_1_name) { 'review-my-review-app' }
        let(:namespace_2_name) { 'review-apps' } # This is not a review apps namespace, so we should not try to delete it

        it 'only deletes the review app namespaces' do
          expect(instance).to receive(:run_command).with("kubectl delete namespace --now --ignore-not-found #{namespace_1_name}")

          subject
        end
      end

      context 'when all namespaces are review app namespaces' do
        let(:namespace_1_name) { 'review-my-review-app' }
        let(:namespace_2_name) { 'review-another-review-app' }

        it 'deletes all of the stale namespaces' do
          expect(instance).to receive(:run_command).with("kubectl delete namespace --now --ignore-not-found #{namespace_1_name} #{namespace_2_name}")

          subject
        end
      end
    end
  end

  describe '#delete_pvc' do
    let(:pvc_name) { 'my-pvc' }

    subject { instance.delete_pvc(pvc_name, pvc_namespace) }

    context 'when the namespace is not a review app namespace' do
      let(:pvc_namespace) { 'not-a-review-app-namespace' }

      it 'does not delete the pvc' do
        expect(instance).not_to receive(:run_command).with(/kubectl delete pvc/)

        subject
      end
    end

    context 'when the namespace is a review app namespace' do
      let(:pvc_namespace) { 'review-apple-test' }

      it 'deletes the pvc' do
        expect(instance).to receive(:run_command).with("kubectl delete pvc --namespace=#{pvc_namespace} --now --ignore-not-found #{pvc_name}")

        subject
      end
    end
  end

  describe '#delete_namespaces' do
    subject { instance.delete_namespaces(namespaces) }

    context 'when at least one namespace is not a review app namespace' do
      let(:namespaces) { %w[review-ns-1 default] }

      it 'does not delete any namespace' do
        expect(instance).not_to receive(:run_command).with(/kubectl delete namespace/)

        subject
      end
    end

    context 'when all namespaces are review app namespaces' do
      let(:namespaces) { %w[review-ns-1 review-ns-2] }

      it 'deletes the namespaces' do
        expect(instance).to receive(:run_command).with("kubectl delete namespace --now --ignore-not-found #{namespaces.join(' ')}")

        subject
      end
    end
  end

  describe '#pvcs_created_before' do
    subject { instance.pvcs_created_before(created_before: two_days_ago) }

    let(:pvc_1_created_at) { three_days_ago }
    let(:pvc_2_created_at) { three_days_ago }
    let(:pvc_1_namespace) { 'review-first-review-app' }
    let(:pvc_2_namespace) { 'review-second-review-app' }
    let(:kubectl_pvcs_json) do
      <<~JSON
        {
          "apiVersion": "v1",
          "items": [
              {
                  "apiVersion": "v1",
                  "kind": "PersistentVolumeClaim",
                  "metadata": {
                      "creationTimestamp": "#{pvc_1_created_at.utc.iso8601}",
                      "name": "pvc1",
                      "namespace": "#{pvc_1_namespace}"
                  }
              },
              {
                  "apiVersion": "v1",
                  "kind": "PersistentVolumeClaim",
                  "metadata": {
                      "creationTimestamp": "#{pvc_2_created_at.utc.iso8601}",
                      "name": "pvc2",
                      "namespace": "#{pvc_2_namespace}"
                  }
              }
          ]
        }
      JSON
    end

    it 'calls #resource_created_before with the correct parameters' do
      expect(instance).to receive(:resource_created_before).with(resource_type: 'pvc', created_before: two_days_ago)

      subject
    end

    it 'returns a hash with two keys' do
      allow(instance).to receive(:run_command).with(
        "kubectl get pvc --all-namespaces --sort-by='{.metadata.creationTimestamp}' -o json"
      ).and_return(kubectl_pvcs_json)

      expect(subject).to match_array([
        {
          resource_name: 'pvc1',
          namespace: 'review-first-review-app'
        },
        {
          resource_name: 'pvc2',
          namespace: 'review-second-review-app'
        }
      ])
    end
  end

  describe '#namespaces_created_before' do
    subject { instance.namespaces_created_before(created_before: two_days_ago) }

    let(:namespace_1_created_at) { three_days_ago }
    let(:namespace_2_created_at) { three_days_ago }
    let(:namespace_1_name) { 'review-first-review-app' }
    let(:namespace_2_name) { 'review-second-review-app' }
    let(:kubectl_namespaces_json) do
      <<~JSON
        {
          "apiVersion": "v1",
          "items": [
              {
                  "apiVersion": "v1",
                  "kind": "namespace",
                  "metadata": {
                      "creationTimestamp": "#{namespace_1_created_at.utc.iso8601}",
                      "name": "#{namespace_1_name}"
                  }
              },
              {
                  "apiVersion": "v1",
                  "kind": "namespace",
                  "metadata": {
                      "creationTimestamp": "#{namespace_2_created_at.utc.iso8601}",
                      "name": "#{namespace_2_name}"
                  }
              }
          ]
        }
      JSON
    end

    it 'calls #resource_created_before with the correct parameters' do
      expect(instance).to receive(:resource_created_before).with(resource_type: 'namespace', created_before: two_days_ago)

      subject
    end

    it 'returns an array of namespaces' do
      allow(instance).to receive(:run_command).with(
        "kubectl get namespace --all-namespaces --sort-by='{.metadata.creationTimestamp}' -o json"
      ).and_return(kubectl_namespaces_json)

      expect(subject).to match_array(%w[review-first-review-app review-second-review-app])
    end
  end

  describe '#run_command' do
    subject { instance.run_command(command) }

    before do
      # We undo the global mock just for this method
      allow(instance).to receive(:run_command).and_call_original

      # Mock stdout
      allow(instance).to receive(:puts)
    end

    context 'when executing a successful command' do
      let(:command) { 'true' } # https://linux.die.net/man/1/true

      it 'displays the name of the command to stdout' do
        expect(instance).to receive(:puts).with("Running command: `#{command}`")

        subject
      end

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when executing an unsuccessful command' do
      let(:command) { 'false' } # https://linux.die.net/man/1/false

      it 'displays the name of the command to stdout' do
        expect(instance).to receive(:puts).with("Running command: `#{command}`")

        expect { subject }.to raise_error(described_class::CommandFailedError)
      end

      it 'raises an error' do
        expect { subject }.to raise_error(described_class::CommandFailedError)
      end
    end
  end
end
