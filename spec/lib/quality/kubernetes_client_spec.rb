# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Quality::KubernetesClient do
  let(:namespace) { 'review-apps-ee' }
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

  describe '#cleanup' do
    before do
      allow(subject).to receive(:raw_resource_names).and_return(raw_resource_names)
    end

    it 'raises an error if the Kubernetes command fails' do
      expect(Gitlab::Popen).to receive(:popen_with_detail)
        .with(["kubectl delete #{described_class::RESOURCE_LIST} " +
          %(--namespace "#{namespace}" --now --ignore-not-found --include-uninitialized --wait=true -l release="#{release_name}")])
        .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: false)))

      expect { subject.cleanup(release_name: release_name) }.to raise_error(described_class::CommandFailedError)
    end

    it 'calls kubectl with the correct arguments' do
      expect(Gitlab::Popen).to receive(:popen_with_detail)
        .with(["kubectl delete #{described_class::RESOURCE_LIST} " +
          %(--namespace "#{namespace}" --now --ignore-not-found --include-uninitialized --wait=true -l release="#{release_name}")])
        .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: true)))

      expect(Gitlab::Popen).to receive(:popen_with_detail)
        .with([%(kubectl delete --namespace "#{namespace}" #{pod_for_release})])
        .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: true)))

      # We're not verifying the output here, just silencing it
      expect { subject.cleanup(release_name: release_name) }.to output.to_stdout
    end

    context 'with multiple releases' do
      let(:release_name) { %w[my-release my-release-2] }

      it 'raises an error if the Kubernetes command fails' do
        expect(Gitlab::Popen).to receive(:popen_with_detail)
          .with(["kubectl delete #{described_class::RESOURCE_LIST} " +
            %(--namespace "#{namespace}" --now --ignore-not-found --include-uninitialized --wait=true -l 'release in (#{release_name.join(', ')})')])
          .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: false)))

        expect { subject.cleanup(release_name: release_name) }.to raise_error(described_class::CommandFailedError)
      end

      it 'calls kubectl with the correct arguments' do
        expect(Gitlab::Popen).to receive(:popen_with_detail)
          .with(["kubectl delete #{described_class::RESOURCE_LIST} " +
            %(--namespace "#{namespace}" --now --ignore-not-found --include-uninitialized --wait=true -l 'release in (#{release_name.join(', ')})')])
          .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: true)))

        expect(Gitlab::Popen).to receive(:popen_with_detail)
         .with([%(kubectl delete --namespace "#{namespace}" #{pod_for_release})])
         .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: true)))

        # We're not verifying the output here, just silencing it
        expect { subject.cleanup(release_name: release_name) }.to output.to_stdout
      end
    end

    context 'with `wait: false`' do
      it 'raises an error if the Kubernetes command fails' do
        expect(Gitlab::Popen).to receive(:popen_with_detail)
          .with(["kubectl delete #{described_class::RESOURCE_LIST} " +
            %(--namespace "#{namespace}" --now --ignore-not-found --include-uninitialized --wait=false -l release="#{release_name}")])
          .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: false)))

        expect { subject.cleanup(release_name: release_name, wait: false) }.to raise_error(described_class::CommandFailedError)
      end

      it 'calls kubectl with the correct arguments' do
        expect(Gitlab::Popen).to receive(:popen_with_detail)
          .with(["kubectl delete #{described_class::RESOURCE_LIST} " +
            %(--namespace "#{namespace}" --now --ignore-not-found --include-uninitialized --wait=false -l release="#{release_name}")])
          .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: true)))

        expect(Gitlab::Popen).to receive(:popen_with_detail)
          .with([%(kubectl delete --namespace "#{namespace}" #{pod_for_release})])
          .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: true)))

        # We're not verifying the output here, just silencing it
        expect { subject.cleanup(release_name: release_name, wait: false) }.to output.to_stdout
      end
    end
  end

  describe '#raw_resource_names' do
    it 'calls kubectl to retrieve the resource names' do
      expect(Gitlab::Popen).to receive(:popen_with_detail)
        .with(["kubectl get #{described_class::RESOURCE_LIST} " +
          %(--namespace "#{namespace}" -o custom-columns=NAME:.metadata.name)])
        .and_return(Gitlab::Popen::Result.new([], raw_resource_names_str, '', double(success?: true)))

      expect(subject.__send__(:raw_resource_names)).to eq(raw_resource_names)
    end
  end
end
