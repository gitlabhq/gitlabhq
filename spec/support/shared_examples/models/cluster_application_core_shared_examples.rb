# frozen_string_literal: true

RSpec.shared_examples 'cluster application core specs' do |application_name|
  it { is_expected.to belong_to(:cluster) }
  it { is_expected.to validate_presence_of(:cluster) }

  describe '#can_uninstall?' do
    it 'calls allowed_to_uninstall?' do
      expect(subject).to receive(:allowed_to_uninstall?).and_return(true)

      expect(subject.can_uninstall?).to be_truthy
    end
  end

  describe '#name' do
    it 'is .application_name' do
      expect(subject.name).to eq(described_class.application_name)
    end

    it 'is recorded in Clusters::Cluster::APPLICATIONS' do
      expect(Clusters::Cluster::APPLICATIONS[subject.name]).to eq(described_class)
    end
  end

  describe '.association_name' do
    it { expect(described_class.association_name).to eq(:"application_#{subject.name}") }
  end

  describe '#helm_command_module' do
    using RSpec::Parameterized::TableSyntax

    where(:helm_major_version, :expected_helm_command_module) do
      2 | Gitlab::Kubernetes::Helm::V2
      3 | Gitlab::Kubernetes::Helm::V3
    end

    with_them do
      subject { described_class.new(cluster: cluster).helm_command_module }

      let(:cluster) { build(:cluster, helm_major_version: helm_major_version) }

      it { is_expected.to eq(expected_helm_command_module) }
    end
  end
end
