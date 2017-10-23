require 'spec_helper'

describe Gcp::Cluster do
  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:service) }

  it { is_expected.to validate_presence_of(:gcp_cluster_zone) }

  describe '.enabled' do
    subject { described_class.enabled }

    let!(:cluster) { create(:gcp_cluster, enabled: true) }

    before do
      create(:gcp_cluster, enabled: false)
    end

    it { is_expected.to contain_exactly(cluster) }
  end

  describe '.disabled' do
    subject { described_class.disabled }

    let!(:cluster) { create(:gcp_cluster, enabled: false) }

    before do
      create(:gcp_cluster, enabled: true)
    end

    it { is_expected.to contain_exactly(cluster) }
  end

  describe '#default_value_for' do
    let(:cluster) { described_class.new }

    it { expect(cluster.gcp_cluster_zone).to eq('us-central1-a') }
    it { expect(cluster.gcp_cluster_size).to eq(3) }
    it { expect(cluster.gcp_machine_type).to eq('n1-standard-4') }
  end

  describe '#validates' do
    subject { cluster.valid? }

    context 'when validates gcp_project_id' do
      let(:cluster) { build(:gcp_cluster, gcp_project_id: gcp_project_id) }

      context 'when valid' do
        let(:gcp_project_id) { 'gcp-project-12345' }

        it { is_expected.to be_truthy }
      end

      context 'when empty' do
        let(:gcp_project_id) { '' }

        it { is_expected.to be_falsey }
      end

      context 'when too long' do
        let(:gcp_project_id) { 'A' * 64 }

        it { is_expected.to be_falsey }
      end

      context 'when includes abnormal character' do
        let(:gcp_project_id) { '!!!!!!' }

        it { is_expected.to be_falsey }
      end
    end

    context 'when validates gcp_cluster_name' do
      let(:cluster) { build(:gcp_cluster, gcp_cluster_name: gcp_cluster_name) }

      context 'when valid' do
        let(:gcp_cluster_name) { 'test-cluster' }

        it { is_expected.to be_truthy }
      end

      context 'when empty' do
        let(:gcp_cluster_name) { '' }

        it { is_expected.to be_falsey }
      end

      context 'when too long' do
        let(:gcp_cluster_name) { 'A' * 64 }

        it { is_expected.to be_falsey }
      end

      context 'when includes abnormal character' do
        let(:gcp_cluster_name) { '!!!!!!' }

        it { is_expected.to be_falsey }
      end
    end

    context 'when validates gcp_cluster_size' do
      let(:cluster) { build(:gcp_cluster, gcp_cluster_size: gcp_cluster_size) }

      context 'when valid' do
        let(:gcp_cluster_size) { 1 }

        it { is_expected.to be_truthy }
      end

      context 'when zero' do
        let(:gcp_cluster_size) { 0 }

        it { is_expected.to be_falsey }
      end
    end

    context 'when validates project_namespace' do
      let(:cluster) { build(:gcp_cluster, project_namespace: project_namespace) }

      context 'when valid' do
        let(:project_namespace) { 'default-namespace' }

        it { is_expected.to be_truthy }
      end

      context 'when empty' do
        let(:project_namespace) { '' }

        it { is_expected.to be_truthy }
      end

      context 'when too long' do
        let(:project_namespace) { 'A' * 64 }

        it { is_expected.to be_falsey }
      end

      context 'when includes abnormal character' do
        let(:project_namespace) { '!!!!!!' }

        it { is_expected.to be_falsey }
      end
    end

    context 'when validates restrict_modification' do
      let(:cluster) { create(:gcp_cluster) }

      before do
        cluster.make_creating!
      end

      context 'when created' do
        before do
          cluster.make_created!
        end

        it { is_expected.to be_truthy }
      end

      context 'when creating' do
        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#state_machine' do
    let(:cluster) { build(:gcp_cluster) }

    context 'when transits to created state' do
      before do
        cluster.gcp_token = 'tmp'
        cluster.gcp_operation_id = 'tmp'
        cluster.make_created!
      end

      it 'nullify gcp_token and gcp_operation_id' do
        expect(cluster.gcp_token).to be_nil
        expect(cluster.gcp_operation_id).to be_nil
        expect(cluster).to be_created
      end
    end

    context 'when transits to errored state' do
      let(:reason) { 'something wrong' }

      before do
        cluster.make_errored!(reason)
      end

      it 'sets status_reason' do
        expect(cluster.status_reason).to eq(reason)
        expect(cluster).to be_errored
      end
    end
  end

  describe '#project_namespace_placeholder' do
    subject { cluster.project_namespace_placeholder }

    let(:cluster) { create(:gcp_cluster) }

    it 'returns a placeholder' do
      is_expected.to eq("#{cluster.project.path}-#{cluster.project.id}")
    end
  end

  describe '#on_creation?' do
    subject { cluster.on_creation? }

    let(:cluster) { create(:gcp_cluster) }

    context 'when status is creating' do
      before do
        cluster.make_creating!
      end

      it { is_expected.to be_truthy }
    end

    context 'when status is created' do
      before do
        cluster.make_created!
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#api_url' do
    subject { cluster.api_url }

    let(:cluster) { create(:gcp_cluster, :created_on_gke) }
    let(:api_url) { 'https://' + cluster.endpoint }

    it { is_expected.to eq(api_url) }
  end

  describe '#restrict_modification' do
    subject { cluster.restrict_modification }

    let(:cluster) { create(:gcp_cluster) }

    context 'when status is created' do
      before do
        cluster.make_created!
      end

      it { is_expected.to be_truthy }
    end

    context 'when status is creating' do
      before do
        cluster.make_creating!
      end

      it { is_expected.to be_falsey }

      it 'sets error' do
        is_expected.to be_falsey
        expect(cluster.errors).not_to be_empty
      end
    end
  end
end
