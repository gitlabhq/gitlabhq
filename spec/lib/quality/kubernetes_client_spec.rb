# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Quality::KubernetesClient do
  let(:namespace) { 'review-apps-ee' }
  let(:release_name) { 'my-release' }

  subject { described_class.new(namespace: namespace) }

  describe '#cleanup' do
    it 'raises an error if the Kubernetes command fails' do
      expect(Gitlab::Popen).to receive(:popen_with_detail)
        .with([%(kubectl --namespace "#{namespace}" delete ) \
          'ingress,svc,pdb,hpa,deploy,statefulset,job,pod,secret,configmap,pvc,secret,clusterrole,clusterrolebinding,role,rolebinding,sa ' \
          "--now --ignore-not-found --include-uninitialized -l release=\"#{release_name}\""])
        .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: false)))

      expect { subject.cleanup(release_name: release_name) }.to raise_error(described_class::CommandFailedError)
    end

    it 'calls kubectl with the correct arguments' do
      expect(Gitlab::Popen).to receive(:popen_with_detail)
        .with([%(kubectl --namespace "#{namespace}" delete ) \
          'ingress,svc,pdb,hpa,deploy,statefulset,job,pod,secret,configmap,pvc,secret,clusterrole,clusterrolebinding,role,rolebinding,sa ' \
          "--now --ignore-not-found --include-uninitialized -l release=\"#{release_name}\""])
        .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: true)))

      # We're not verifying the output here, just silencing it
      expect { subject.cleanup(release_name: release_name) }.to output.to_stdout
    end
  end
end
