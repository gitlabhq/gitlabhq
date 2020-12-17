# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kubernetes::Helm::V2::ResetCommand do
  subject(:reset_command) { described_class.new(name: name, rbac: rbac, files: files) }

  let(:rbac) { true }
  let(:name) { 'helm' }
  let(:files) { {} }

  it_behaves_like 'helm command generator' do
    let(:commands) do
      <<~EOS
      export HELM_HOST="localhost:44134"
      tiller -listen ${HELM_HOST} -alsologtostderr &
      helm init --client-only
      helm reset --force
      EOS
    end
  end

  describe '#pod_name' do
    subject { reset_command.pod_name }

    it { is_expected.to eq('uninstall-helm') }
  end

  it_behaves_like 'helm command' do
    let(:command) { reset_command }
  end
end
