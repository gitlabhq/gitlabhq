require 'spec_helper'

describe Clusters::Providers::Gcp do
  it { is_expected.to belong_to(:cluster) }
  it { is_expected.to validate_presence_of(:zone) }

  describe 'default_value_for' do
    let(:gcp) { build(:cluster_provider_gcp) }

    it "has default value" do
      expect(gcp.zone).to eq('us-central1-a')
      expect(gcp.num_nodes).to eq(3)
      expect(gcp.machine_type).to eq('n1-standard-2')
    end
  end

  describe 'validation' do
    subject { gcp.valid? }

    context 'when validates gcp_project_id' do
      let(:gcp) { build(:cluster_provider_gcp, gcp_project_id: gcp_project_id) }

      context 'when gcp_project_id is shorter than 1' do
        let(:gcp_project_id) { '' }

        it { is_expected.to be_falsey }
      end

      context 'when gcp_project_id is longer than 63' do
        let(:gcp_project_id) { 'a' * 64 }

        it { is_expected.to be_falsey }
      end

      context 'when gcp_project_id includes invalid character' do
        let(:gcp_project_id) { '!!!!!!' }

        it { is_expected.to be_falsey }
      end

      context 'when gcp_project_id is valid' do
        let(:gcp_project_id) { 'gcp-project-1' }

        it { is_expected.to be_truthy }
      end
    end

    context 'when validates num_nodes' do
      let(:gcp) { build(:cluster_provider_gcp, num_nodes: num_nodes) }

      context 'when num_nodes is string' do
        let(:num_nodes) { 'A3' }

        it { is_expected.to be_falsey }
      end

      context 'when num_nodes is nil' do
        let(:num_nodes) { nil }

        it { is_expected.to be_falsey }
      end

      context 'when num_nodes is smaller than 1' do
        let(:num_nodes) { 0 }

        it { is_expected.to be_falsey }
      end

      context 'when num_nodes is valid' do
        let(:num_nodes) { 3 }

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#state_machine' do
    context 'when any => [:created]' do
      let(:gcp) { build(:cluster_provider_gcp, :creating) }

      before do
        gcp.make_created
      end

      it 'nullify access_token and operation_id' do
        expect(gcp.access_token).to be_nil
        expect(gcp.operation_id).to be_nil
        expect(gcp).to be_created
      end
    end

    context 'when any => [:creating]' do
      let(:gcp) { build(:cluster_provider_gcp) }

      context 'when operation_id is present' do
        let(:operation_id) { 'operation-xxx' }

        before do
          gcp.make_creating(operation_id)
        end

        it 'sets operation_id' do
          expect(gcp.operation_id).to eq(operation_id)
          expect(gcp).to be_creating
        end
      end

      context 'when operation_id is nil' do
        let(:operation_id) { nil }

        it 'raises an error' do
          expect { gcp.make_creating(operation_id) }
            .to raise_error('operation_id is required')
        end
      end
    end

    context 'when any => [:errored]' do
      let(:gcp) { build(:cluster_provider_gcp, :creating) }
      let(:status_reason) { 'err msg' }

      it 'nullify access_token and operation_id' do
        gcp.make_errored(status_reason)

        expect(gcp.access_token).to be_nil
        expect(gcp.operation_id).to be_nil
        expect(gcp.status_reason).to eq(status_reason)
        expect(gcp).to be_errored
      end

      context 'when status_reason is nil' do
        let(:gcp) { build(:cluster_provider_gcp, :errored) }

        it 'does not set status_reason' do
          gcp.make_errored(nil)

          expect(gcp.status_reason).not_to be_nil
        end
      end
    end
  end

  describe '#on_creation?' do
    subject { gcp.on_creation? }

    context 'when status is creating' do
      let(:gcp) { create(:cluster_provider_gcp, :creating) }

      it { is_expected.to be_truthy }
    end

    context 'when status is created' do
      let(:gcp) { create(:cluster_provider_gcp, :created) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#api_client' do
    subject { gcp.api_client }

    context 'when status is creating' do
      let(:gcp) { build(:cluster_provider_gcp, :creating) }

      it 'returns Cloud Platform API clinet' do
        expect(subject).to be_an_instance_of(GoogleApi::CloudPlatform::Client)
        expect(subject.access_token).to eq(gcp.access_token)
      end
    end

    context 'when status is created' do
      let(:gcp) { build(:cluster_provider_gcp, :created) }

      it { is_expected.to be_nil }
    end

    context 'when status is errored' do
      let(:gcp) { build(:cluster_provider_gcp, :errored) }

      it { is_expected.to be_nil }
    end
  end
end
