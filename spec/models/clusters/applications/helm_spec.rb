require 'rails_helper'

describe Clusters::Applications::Helm do
  include_examples 'cluster application core specs', :clusters_applications_helm

  describe '.installed' do
    subject { described_class.installed }

    let!(:cluster) { create(:clusters_applications_helm, :installed) }

    before do
      create(:clusters_applications_helm, :errored)
    end

    it { is_expected.to contain_exactly(cluster) }
  end

  describe '#install_command' do
    let(:helm) { create(:clusters_applications_helm) }

    subject { helm.install_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::InitCommand) }

    it 'should be initialized with 1 arguments' do
      expect(subject.name).to eq('helm')
    end
  end
end
