# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Providers::Gcp do
  it { is_expected.to belong_to(:cluster) }
  it { is_expected.to validate_presence_of(:zone) }

  include_examples 'provider status', :cluster_provider_gcp

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

  describe '#has_rbac_enabled?' do
    subject { gcp.has_rbac_enabled? }

    context 'when cluster is legacy_abac' do
      let(:gcp) { create(:cluster_provider_gcp, :abac_enabled) }

      it { is_expected.to be_falsey }
    end

    context 'when cluster is not legacy_abac' do
      let(:gcp) { create(:cluster_provider_gcp) }

      it { is_expected.to be_truthy }
    end
  end

  describe '#knative_pre_installed?' do
    subject { gcp.knative_pre_installed? }

    context 'when cluster is cloud_run' do
      let(:gcp) { create(:cluster_provider_gcp) }

      it { is_expected.to be_falsey }
    end

    context 'when cluster is not cloud_run' do
      let(:gcp) { create(:cluster_provider_gcp, :cloud_run_enabled) }

      it { is_expected.to be_truthy }
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

  describe '#nullify_credentials' do
    let(:provider) { create(:cluster_provider_gcp, :creating) }

    before do
      expect(provider.access_token).to be_present
      expect(provider.operation_id).to be_present
    end

    it 'removes access_token and operation_id' do
      provider.nullify_credentials

      expect(provider.access_token).to be_nil
      expect(provider.operation_id).to be_nil
    end
  end

  describe '#assign_operation_id' do
    let(:provider) { create(:cluster_provider_gcp, :scheduled) }
    let(:operation_id) { 'operation-123' }

    it 'sets operation_id' do
      provider.assign_operation_id(operation_id)

      expect(provider.operation_id).to eq(operation_id)
    end
  end
end
