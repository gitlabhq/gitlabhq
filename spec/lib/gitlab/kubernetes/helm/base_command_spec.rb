# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Kubernetes::Helm::BaseCommand do
  subject(:base_command) do
    test_class.new(rbac)
  end

  let(:application) { create(:clusters_applications_helm) }
  let(:rbac) { false }

  let(:test_class) do
    Class.new(Gitlab::Kubernetes::Helm::BaseCommand) do
      def initialize(rbac)
        super(
          name: 'test-class-name',
          rbac: rbac,
          files: { some: 'value' },
          local_tiller_enabled: false
        )
      end
    end
  end

  it_behaves_like 'helm command generator' do
    let(:commands) { '' }
  end

  describe '#pod_name' do
    subject { base_command.pod_name }

    it { is_expected.to eq('install-test-class-name') }
  end

  it_behaves_like 'helm command' do
    let(:command) { base_command }
  end
end
