# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kubernetes::Helm::V3::DeleteCommand do
  subject(:delete_command) { described_class.new(name: app_name, rbac: rbac, files: files) }

  let(:app_name) { 'app-name' }
  let(:rbac) { true }
  let(:files) { {} }

  it_behaves_like 'helm command generator' do
    let(:commands) do
      <<~EOS
      helm uninstall app-name --namespace gitlab-managed-apps
      EOS
    end
  end

  describe '#pod_name' do
    subject { delete_command.pod_name }

    it { is_expected.to eq('uninstall-app-name') }
  end

  it_behaves_like 'helm command' do
    let(:command) { delete_command }
  end

  describe '#delete_command' do
    it 'deletes the release' do
      expect(subject.delete_command).to eq('helm uninstall app-name --namespace gitlab-managed-apps')
    end
  end
end
