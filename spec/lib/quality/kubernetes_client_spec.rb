# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Quality::KubernetesClient do
  let(:namespace) { 'review-apps-ee' }
  let(:release_name) { 'my-release' }

  subject { described_class.new(namespace: namespace) }

  describe '#cleanup' do
    it 'calls helm list with default arguments' do
      expect(Gitlab::Popen).to receive(:popen_with_detail)
        .with([
          %(kubectl),
          %(-n "#{namespace}" get ingress,svc,pdb,hpa,deploy,statefulset,job,pod,secret,configmap,pvc,secret,clusterrole,clusterrolebinding,role,rolebinding,sa 2>&1),
          '|',
          %(grep "#{release_name}"),
          '|',
          "awk '{print $1}'",
          '|',
          %(xargs kubectl -n "#{namespace}" delete),
          '||',
          'true'
        ])
        .and_return(Gitlab::Popen::Result.new([], ''))

      subject.cleanup(release_name: release_name)
    end
  end
end
